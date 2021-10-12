/*
	Hacer un trigger que al ingresar una colaboración obtenga el precio de la
	misma a partir del precio hora base del tipo de tarea. Tener en cuenta que si el
	colaborador es externo el costo debe ser un 20% más caro.
*/

create trigger tr_punto1 on Colaboraciones
after insert as
begin
	begin try
		begin transaction
			
			declare @IDColaborador int, @IDTarea int, @PrecioHora money, @Tipo char
			select @IDColaborador = IDColaborador, @IDTarea = IDTarea from inserted

			select @PrecioHora = tt.PrecioHoraBase from Tareas t
			inner join TiposTarea tt on tt.ID = t.IDTipo
			where t.ID = @IDTarea

			select @Tipo = c.Tipo from Colaboradores c
			where c.ID = @IDColaborador

			if @Tipo like '%E%'
			begin
				set @PrecioHora = @PrecioHora * 1.2
			end

			update Colaboraciones set PrecioHora = @PrecioHora where IDColaborador = @IDColaborador and IDTarea = @IDTarea

		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error en el trigger tr_punto1', 15, 10)
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
	'Programación' se agreguen automáticamente dos tareas de tipo 'Testing
	unitario' y 'Testing de integración' de 4 horas cada una. La fecha de inicio y fin
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
			where Nombre = 'Testing de integración'

			select @IDtu = ID from TiposTarea
			where Nombre = 'Testing unitario'

			if @Nombre like '%Programación%'
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
	Hacer un trigger que al borrar una tarea realice una baja lógica de la misma en
	lugar de una baja física.
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
	Hacer un trigger que al borrar un módulo realice una baja lógica del mismo en
	lugar de una baja física. Además, debe borrar todas las tareas asociadas al
	módulo
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
	Hacer un trigger que al borrar un proyecto realice una baja lógica del mismo
	en lugar de una baja física. Además, debe borrar todas los módulos asociados
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
	fecha estimada de fin del módulo asociado a la tarea entonces se modifique
	la fecha estimada de fin en el módulo.
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

go

/*
	Hacer un trigger que al borrar una tarea que previamente se ha dado de baja
	lógica realice la baja física de la misma.
*/

create trigger DeleteTareas on Tareas
after delete as
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
		raiserror('Error en trigger DeleteTareas',16,2)
	end catch
end

go

/*
	Hacer un trigger que al ingresar una colaboración no permita que el
	colaborador/a superponga las fechas con las de otras colaboraciones que se
	les hayan asignado anteriormente. En caso contrario, registrar la colaboración
	sino generar un error con un mensaje aclaratorio.
*/

create trigger ColaboracionesFechas on Colaboraciones
instead of insert as
begin
	begin try
		begin transaction
			
			declare @IDColaborador int, @IDTarea int, @FIncio date, @FFin date, @Coincidencias int
			
			set @Coincidencias = 0

			select @IDColaborador = IDColaborador, @IDTarea = IDTarea from inserted

			select @FIncio = FechaInicio, @FFin = FechaFin from Tareas
			where ID = @IDTarea

			select @Coincidencias = count(*) from Colaboraciones C
			inner join Tareas t on t.ID = C.IDTarea
			where @FIncio = T.FechaInicio or @FFin =FechaFin

			if @Coincidencias > 0
			begin
				raiserror('Fechas de colaboraciones superpuestas', 16, 2)
			end
 
		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error en trigger ColaboracionesFechas', 16, 2)
	end catch
end

go

/*
	Hacer un trigger que al modificar el precio hora base de un tipo de tarea
	registre en una tabla llamada HistorialPreciosTiposTarea el ID, el precio antes
	de modificarse y la fecha de modificación.
	NOTA: La tabla debe estar creada previamente. NO crearla dentro del trigger
*/

create table HistorialPreciosTiposTarea
(
	ID smallint primary key identity(1,1) not null,
	IDTipoTarea smallint foreign key references TiposTarea(ID) not null,
	Precio money not null,
	FechaModificacion date not null
)

go

create trigger PrecioHora on TiposTarea
after update as
begin
	begin try
		begin transaction
			
			declare @IDTiposTarea smallint, @Precio money

			select @IDTiposTarea = ID, @Precio = PrecioHoraBase from deleted

			insert into HistorialPreciosTiposTarea (IDTipoTarea, Precio, FechaModificacion) values (@IDTiposTarea, @Precio, getdate())

		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error en triger PrecioHora',16,2)
	end catch
end
