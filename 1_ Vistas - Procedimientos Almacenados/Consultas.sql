use BluePrint

go

/*
	Hacer un reporte que liste por cada tipo de tarea se liste el nombre, el precio
	de hora base y el promedio de valor hora real (obtenido de las
	colaboraciones)
*/

create view vw_tipoTarea as
	select tt.Nombre, tt.PrecioHoraBase, avg(c.PrecioHora) as promedio from TiposTarea tt
	inner join Tareas t on t.IDTipo = tt.ID
	inner join Colaboraciones c on c.IDTarea = t.ID
	group by tt.Nombre, tt.PrecioHoraBase

go

/*
	Modificar el reporte de (1) para que también liste una columna llamada
	Variación con las siguientes reglas:
	Poca → Si la diferencia entre el promedio y el precio de hora base es menor a
	$500.
	Mediana → Si la diferencia entre el promedio y el precio de hora base está
	entre $501 y $999.
	Alta → Si la diferencia entre el promedio y el precio de hora base es $1000 o
	más.
*/

alter view vw_tipoTarea as
	select tn.Nombre, tn.PrecioHoraBase, tn.promedio,
	case
		when (tn.promedio - tn.PrecioHoraBase) > 500 then 'Poca'
		when (tn.promedio - tn.PrecioHoraBase) < 500 and (tn.promedio - tn.PrecioHoraBase) > 1000  then 'Mediana'
		when (tn.promedio - tn.PrecioHoraBase) < 1000 then 'Alta'
	end as diferencia
	from 
	(
		select tt.Nombre, tt.PrecioHoraBase, avg(c.PrecioHora) as promedio from TiposTarea tt
		inner join Tareas t on t.IDTipo = tt.ID
		inner join Colaboraciones c on c.IDTarea = t.ID
		group by tt.Nombre, tt.PrecioHoraBase
	) as tn

go

/*
	Crear un procedimiento almacenado que liste las colaboraciones de un
	colaborador cuyo ID se envía como parámetro.
*/

create procedure SP_ListaColaboraciones
(
	@ID int
)
as
begin
	begin try
		if @ID >0
			begin
				select * from Colaboraciones c
				where c.IDColaborador = @ID
			end
			else begin
				raiserror ('Erro de ID', 15, 10)
			end
	end try
	begin catch
		raiserror ('Erro de ID', 15, 10)
	end catch
end

go
/*
	Hacer una vista que liste por cada colaborador el apellido y nombre, el nombre
	del tipo (Interno o Externo) y la cantidad de proyectos distintos en los que
	haya trabajado.
*/

create view VW_Colaboradores as
	select c.Nombre, c.Apellido,
	case
		when c.Tipo = 'I' then 'Interno'
		else 'Externo'
	end as Tipo,
	(
		select distinct count(*) from Proyectos p
		inner join Modulos m on m.IDProyecto = p.ID
		inner join Tareas t on t.IDModulo = m.ID
		inner join Colaboraciones co on co.IDTarea = t.ID
		where co.IDColaborador = c.ID
	) as CantColaboraciones
	from Colaboradores c

go

/*
	Hacer un procedimiento almacenado que reciba dos fechas como parámetro y
	liste todos los datos de los proyectos que se encuentren entre esas fechas.
*/

create procedure SP_ListProyectSetDate
(
	@Date1 date,
	@Date2 date
)
as
begin
	begin try
		if @Date1 > @Date2
		begin
			select * from Proyectos p
			where p.FechaInicio >= @Date1 and p.FechaFin <= @Date2
		end
		else
		begin
			raiserror('La segunda fecha es menor que la primera', 15, 10)
		end
	end try
	begin catch
		raiserror('Error con las fechas', 15, 10)
	end catch
end

go

/*
	Hacer un procedimiento almacenado que reciba un ID de Cliente, un ID de Tipo
	de contacto y un valor y modifique los datos de contacto de dicho cliente. El ID
	de Tipo de contacto puede ser: 1 - Email, 2 - Teléfono y 3 - Celular.
*/

create procedure SP_ModificarCliente 
(
	@IDCliente int,
	@IDTipoContacto int,
	@Valor tinyint
) as
begin
	begin try
		begin transaction
			if @Valor = 1
			begin
				update Clientes set EMail = @Valor where ID = @IDCliente
				commit transaction
			end
			else if @Valor = 2
			begin
				update Clientes set Telefono = @Valor where ID = @IDCliente
				commit transaction
			end
			else if @Valor = 3
			begin
				update Clientes set Celular = @Valor where ID = @IDCliente
				commit transaction
			end
			else 
			begin
				raiserror('Error en el valor ingresado', 15, 10)
			end
	end try
	begin catch
		rollback transaction
		raiserror('Error no se ejecturo ningun cambio en la base de datos', 15, 10)
	end catch
end

/*
	Hacer un procedimiento almacenado que reciba un ID de Módulo y realice la
	baja lógica tanto del módulo como de todas sus tareas futuras. Utilizar una
	transacción para realizar el proceso de manera atómica.
*/

create procedure SP_BalaModulos
(
	@ID int
) as
begin
	begin try
		begin transaction
		if @ID > 0
		begin
			update Modulos
				set Estado = 0
				where ID = @ID
			update Tareas
				set Estado = 0
				where FechaInicio > GETDATE() and IDModulo = @ID
			commit transaction
		end
		else 
		begin
			raiserror('Error el ID debe ser positivo', 15, 10)
		end
	end try
	begin catch
		rollback transaction
		raiserror('Error baja no realizada', 15, 10)
	end catch
end
