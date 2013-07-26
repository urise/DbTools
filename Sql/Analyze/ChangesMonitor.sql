-- log table
create table __oplogs (
	id int not null identity,
	dt datetime not null,
	operation varchar(1),
	tablename varchar(128),
	pk int null
)
-- creating triggers for all the tables
SELECT  
	'create trigger tr_oplogs_' + tc.TABLE_NAME + ' on dbo.' + tc.TABLE_NAME + ' ' + 
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
	values (GETDATE(), @operation, ''' + tc.TABLE_NAME + ''', @id)'
FROM    information_schema.table_constraints tc
            JOIN information_schema.constraint_column_usage ccu
                ON tc.constraint_name = ccu.Constraint_name
WHERE   tc.constraint_type = 'Primary Key'


-- drop triggers
select 'drop trigger tr_oplogs_' + tc.TABLE_NAME
FROM    information_schema.table_constraints tc
            JOIN information_schema.constraint_column_usage ccu
                ON tc.constraint_name = ccu.Constraint_name
            join sys.all_columns c on ccu.column_name = c.name
              and tc.TABLE_NAME = OBJECT_NAME(c.object_id)
WHERE   tc.constraint_type = 'Primary Key'