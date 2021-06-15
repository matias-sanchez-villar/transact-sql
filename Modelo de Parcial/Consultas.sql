/*
	Hacer un trigger que al cargar un crédito verifique que el importe del mismo sumado
	a los importes de los créditos que actualmente solicitó esa persona no supere al
	triple de la declaración de ganancias. Sólo deben tenerse en cuenta en la sumatoria
	los créditos que no se encuentren cancelados. De no poder otorgar el crédito
	aclararlo con un mensaje
*/

Create trigger TR_CargaCredito on Creditos
after insert as
begin
	begin try
		begin transaction
			declare @ID bigint, @DNI varchar(10), @Ganancias money, @ImportesAnteriores money
			
			set @ImportesAnteriores = 0
			
			select @ID = ID, @DNI = DNI from inserted
			
			select @ImportesAnteriores = isnull(sum(Importe), 0) from Creditos where @DNI like DNI and Cancelado = 0

			select @Ganancias = p.DeclaracionGanancias from Personas p where p.DNI = @DNI 

			if (@Ganancias * 3) > @ImportesAnteriores
			begin
				rollback transaction
				raiserror('Error monto de credito superior', 16, 2)
			end
			else 
			begin
				commit transaction
			end
	end try
	begin catch
		rollback transaction
		raiserror('Error en la consulta', 16, 2)
	end catch
end

go

/*
	Hacer un trigger que al eliminar un crédito realice la cancelación del mismo.
*/

create trigger TR_EliminarCredito on Creditos
instead of delete as
begin
	begin try
		begin transaction
			declare @IDCredito int
			select @IDCredito = ID from deleted

			update Creditos set Cancelado = 1 where ID = @IDCredito
		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error en la consulta', 16, 2)
	end catch
end

go

/*
	Hacer un trigger que no permita otorgar créditos con un plazo de 20 o más años a
	personas cuya declaración de ganancias sea menor al promedio de declaración de
	ganancias.
*/

create trigger TR_OtorgarCreditos on Creditos
after insert as
begin
	begin try
		begin transaction
			declare @Plazo smallint, @DNI varchar(10), @ID int, @Ganancias money, @PromGanancias money
			select @Plazo = Plazo, @DNI =DNI, @ID = ID from Creditos

			select @Ganancias = DeclaracionGanancias from Personas where @DNI like DNI

			select @PromGanancias = avg(isnull(DeclaracionGanancias, 0)) from Personas

			if @Plazo > 20 and @PromGanancias > @Ganancias
			begin
				rollback transaction
				raiserror('Error promedio de ganancias menor a las ganancias del sujeto', 16, 2)
			end
			else 
			begin
				commit transaction
			end
	end try
	begin catch
		rollback transaction
		raiserror('Error en la consulta', 16, 2)
	end catch
end

go

/*
	Hacer un procedimiento almacenado que reciba dos fechas y liste todos los créditos
	otorgados entre esas fechas. Debe listar el apellido y nombre del solicitante, el
	nombre del banco, el tipo de banco, la fecha del crédito y el importe solicitado.
*/

create procedure PR_FechasDescriptivas
(
	@Fecha1 date,
	@Fecha2 date
) as
begin
	begin try
		begin transaction
			select p.Nombres, p.Apellidos, b.Nombre, b.Tipo, c.Fecha, c.Importe from Creditos c
			inner join personas p on p.DNI = c.DNI
			inner join Bancos b on b.ID = c.IDBanco
			where @Fecha1 < c.Fecha and @Fecha2 > c.Fecha
		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error fechas incorrectas', 16, 2)
	end catch
end