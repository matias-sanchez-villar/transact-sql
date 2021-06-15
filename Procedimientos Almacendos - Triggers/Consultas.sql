/*
	Hacer un trigger que al ingresar una colaboración obtenga el precio de la
	misma a partir del precio hora base del tipo de tarea. Tener en cuenta que si el
	colaborador es externo el costo debe ser un 20% más caro.
*/

create trigger TR_NuevaColaboracion on Colaboraciones
after insert as
	begin
	begin try
		begin transaction
			declare @IDColaborador int, @IDTarea int, @PrecioHora money, @TipoColaborador char
			select @IDColaborador = c.IDColaborador, @IDTarea = c.IDTarea from Colaboraciones c
			
			select @PrecioHora = tt.PrecioHoraBase from TiposTarea tt
			inner join Tareas t on t.IDTipo = tt.ID
			where t.ID = @IDTarea

			select @TipoColaborador = cc.Tipo from Colaboradores cc
			where cc.ID = @IDColaborador

			if @TipoColaborador = 'E'
			begin
				set @PrecioHora = @PrecioHora * 1.2
			end

			update Colaboraciones set PrecioHora = @PrecioHora where IDColaborador = @IDColaborador and IDTarea = @IDTarea

		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('No se pudo ejecutar la consulta', 16, 10)
	end catch
end

go

/*
	Hacer un trigger que no permita que un colaborador registre más de 15 tareas
	en un mismo mes. De lo contrario generar un error con un mensaje aclaratorio.
*/

create trigger TR_Tareas on Colaboraciones
after insert as
begin
	begin try
		begin transaction
			declare @IDTarea int, @IDColaborador int, @CantidadColaboraciones int

			select @IDTarea = IDTarea, @IDColaborador = IDColaborador from inserted

			select @CantidadColaboraciones = COUNT(*) from Tareas
			where @IDTarea =ID

		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error intente nuevamente', 16, 10)
	end catch
end

select * from tareas

select count(*) from Colaboraciones c
inner join Tareas t on t.ID = c.IDTarea
where c.IDColaborador = 5 and t.FechaInicio