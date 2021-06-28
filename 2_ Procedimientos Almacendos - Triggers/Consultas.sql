/*
	Hacer un trigger que al ingresar una colaboraci�n obtenga el precio de la
	misma a partir del precio hora base del tipo de tarea. Tener en cuenta que si el
	colaborador es externo el costo debe ser un 20% m�s caro.
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
	Hacer un trigger que no permita que un colaborador registre m�s de 15 tareas
	en un mismo mes. De lo contrario generar un error con un mensaje aclaratorio.
*/

create trigger TR_Tareas on Colaboraciones
after insert as
begin
	begin try
		begin transaction
			declare @IDColaborador int, @CantColaboraciones int

			select @IDColaborador = IDColaborador from inserted

			select @CantColaboraciones = count(*) from Colaboraciones
			where @IDColaborador = IDColaborador and MONTH(Tiempo) = MONTH(GETDATE()) and year(Tiempo) = year(GETDATE())
				
			if @CantColaboraciones >= 15
			begin
				raiserror('Error tienes mas de 15 colaboraciones en este mes', 16, 10)
			end

		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error intente nuevamente', 16, 10)
	end catch
end

go

/*
	Hacer un trigger que al ingresar una tarea cuyo tipo contenga el nombre
	'Programaci�n' se agreguen autom�ticamente dos tareas de tipo 'Testing
	unitario' y 'Testing de integraci�n' de 4 horas cada una. La fecha de inicio y fin
	de las mismas debe ser NULL. Calcular el costo estimado de la tarea.
*/

create trigger TestingAuto on Tareas
after insert as
begin
	begin try
		begin transaction
			declare @Nombre varchar(50), @IDTipo int, @IDModulo int, @IDti int, @IDtu int

			select @IDTipo = IDTipo, @IDModulo = IDModulo from inserted

			select @Nombre = Nombre from TiposTarea where @IDTipo = ID

			select @IDti = ID from TiposTarea
			where Nombre = 'Testing de integraci�n'

			select @IDtu = ID from TiposTarea
			where Nombre = 'Testing unitario'

			if @Nombre like '%Programaci�n%'
			begin
			
				insert into Tareas(IDModulo, IDTipo, Estado) VALUES (@IDModulo, @IDti, 1)
				insert into Tareas(IDModulo, IDTipo, Estado) VALUES (@IDModulo, @IDtu, 1)

			end

		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error en trigger TestingAuto',16,2)
	end catch
end

go

/*
	Hacer un trigger que al borrar una tarea realice una baja l�gica de la misma en
	lugar de una baja f�sica.
*/

create trigger BajaLogicaTareas on Tareas
instead of delete as
begin
	begin try
		begin transaction
			
			declare @ID int

			select @ID = ID from deleted

			update Tareas set Estado = 0 where ID = @ID

		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error trigger BajaLogica',16,2)
	end catch
end

go

/*
	Hacer un trigger que al borrar un m�dulo realice una baja l�gica del mismo en
	lugar de una baja f�sica. Adem�s, debe borrar todas las tareas asociadas al
	m�dulo
*/

create trigger BajoLogicaModulo on Modulos
instead of delete as
begin
	begin try
		begin transaction

			declare @ID int

			select @ID = ID from deleted

			update Modulos set Estado = 0 where ID = @ID

			delete from Tareas where IDModulo = @ID
			
		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error en trigger BajaLogicaModulos',16,2)
	end catch
end

go

/*
	Hacer un trigger que al borrar un proyecto realice una baja l�gica del mismo
	en lugar de una baja f�sica. Adem�s, debe borrar todas los m�dulos asociados
	al proyecto.
*/

create trigger BajaLogicaProyectos on Proyectos
instead of delete as
begin
	begin try
		begin transaction
			
			declare @ID int

			select @ID = ID from deleted

			update Proyectos set Estado = 0 where ID = @ID

			delete Modulos where IDProyecto = @ID

		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error trigger BajaLogicaProyectos',16,2)
	end catch
end

go

/*
	Hacer un trigger que si se agrega una tarea cuya fecha de fin es mayor a la
	fecha estimada de fin del m�dulo asociado a la tarea entonces se modifique
	la fecha estimada de fin en el m�dulo.
*/

create trigger ModificarFechaEstimadaFin on tareas
after insert as
begin
	begin try
		begin transaction
			
			declare @FFin date, @FEFin date, @IDModulo int

			select @FFin = FechaInicio, @IDModulo = IDModulo from inserted

			select @FEFin = FechaEstimadaFin from Modulos
			where ID = @IDModulo

			if @FFin > @FEFin
			begin
				
				update Modulos set FechaEstimadaFin = @FFin where ID = @IDModulo

			end

		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error en trigger ModificarFechaEstimadaFin',16,3)
	end catch
end

