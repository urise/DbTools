-- log table
create table __oplogs (
	id int not null identity,
	dt datetime not null,
	operation varchar(1),
	tablename varchar(128),
	pk int null
)
alter view v_oplogs_pk_for_monitoring as
select table_name, column_name
from 
	(select ccu.table_name, column_name, c.system_type_id, 
		count(*) over (partition by ccu.table_name, ccu.constraint_name) as column_count
	 from information_schema.table_constraints tc
		inner join information_schema.constraint_column_usage ccu
			on tc.constraint_name = ccu.constraint_name
			  and tc.table_name = ccu.table_name
		inner join sys.all_columns c
			on ccu.column_name = c.name and ccu.table_name = object_name(object_id)
	where tc.constraint_type = 'Primary Key' ) Q
where Q.column_count = 1 and Q.system_type_id = 56
go
alter view v_oplogs_tables_for_monitoring as
select t.name as table_name, 
	IsNull(pk.column_name, c.name) as column_name
from sys.tables t
  left join v_oplogs_pk_for_monitoring pk
    on t.name = pk.table_name
  left join sys.all_columns c
    on t.name = object_name(c.object_id) and c.system_type_id = 56
		and (c.name = t.name + 'Id' 
			or substring(t.name, 1, 3) = 'tbl'
			  and c.name = substring(t.name, 4, len(t.name) - 3) + 'Id'
		  )
where 
	pk.column_name is not null or c.name is not null		  
go
select
	'create trigger tr_oplogs_' + table_name + ' on dbo.' + table_name + ' ' + 
	N'after insert, delete, update
	as
	declare @operation varchar(1), @id int
	if exists(select * from inserted)
		select @operation = 
			case when exists(select * from deleted) then ''U'' else ''I'' end,
			@id = ' + column_name + N' from inserted
	else
		select @operation = ''D'', @id = ' + column_name + N' from deleted
	insert into __oplogs (dt, operation, tablename, pk)
	values (GETDATE(), @operation, ''' + table_name + ''', @id)'
from v_oplogs_tables_for_monitoring
       
select 'drop trigger ' + name
from sys.triggers
where name like 'tr_oplogs_%'
