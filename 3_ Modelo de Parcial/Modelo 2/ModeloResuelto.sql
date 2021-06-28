--Realizar un trigger que se encargue de verificar que un socio no pueda extraer más de un
--libro a la vez. Se sabrá que un socio tiene un libro sin devolver si contiene un registro en la tabla
--de Préstamos que no tiene fecha de devolución. Si el socio tiene un libro sin devolver el trigger
--no deberá permitir el préstamo y deberá indicarlo con un mensaje aclaratorio. Caso contrario,
--registrar el préstamo.

create trigger LibrosUsuarios on Prestamos
instead of insert as
begin
	begin try
		begin transaction
			
			declare @IDSocio int, @Cantidad int
			select @IDSocio = IDSocio from inserted
			
			select @Cantidad = count(*) from Prestamos
			where IDSocio = @IDSocio and FDevolucion is null

			if @Cantidad > 0
			begin
				rollback transaction
				raiserror(concat('Error contiene ' + @Cantidad + ' Libros sin devolver'),16, 2)
			end

		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error de consulta',15, 22)
	end catch
end

go

--Realizar un procedimiento almacenado que a partir de un número de socio se pueda ver,
--ordenado por fecha decreciente, todos los libros retirados por el socio y que hayan sido
--devueltos

create procedure LibrosRetirados 
(
	@ID int
) as
begin
	begin try
		select * from Prestamos
		where @ID = IDSocio and FDevolucion is not null
		group by FPrestamo desc
	end try
	begin catch
		raiserror('Error en la consulta', 15, 22)
	end catch
end

--Hacer un procedimiento almacenado denominado 'Devolver_Libro' que a partir de un IDLibro
--y una Fecha de devolución, realice la devolución de dicho libro en esa fecha y asigne el costo
--del préstamo que equivale al 10% del valor del libro. Si el libro es devuelto después de siete
--días o más de la fecha de préstamo, el costo del préstamo será del 20% del valor del libro.
--NOTA: Si el libro no se encuentra prestado indicarlo con un mensaje.

create procedure Devolver_Libro
(
	@IDLibro int,
	@FDevolucion date
) as
begin
	begin try
		begin transaction

			Declare @FPrestamo int, @Precio money, @IDSocio int

			select @FPrestamo = FPrestamo, @IDSocio = IDSocio, @Precio =Precio from Prestamos
			where @IDLibro = IDLibro and FDevolucion is not null

			if DATEDIFF(day, @FPrestamo, @FDevolucion) > 7
			begin
				set @Precio = @Precio * 1.20
			end
			else begin
				set @Precio = @Precio * 1.10
			end

			if (select * from Prestamos where @IDLibro = IDLibro and FDevolucion is not null) is not null
			begin
				update Prestamos set FDevolucion = @FDevolucion, Precio = @Precio where @IDLibro = IDLibro and @IDSocio = IDSocio
			end
			else begin
				raiserror('Libro no encontrado', 15, 16)
			end

		commit transaction
	end try
	begin catch
		rollback transaction
		raiserror('Error en la BD', 15, 22)
	end catch
end

--Listar todos los socios que hayan retirado al menos un bestseller. Los datos del socio deben
--aparecer una sola vez en el listado

create view ListSocBesteller
as
select distinc S.ID, S.Nombre, S.Apellido, S.Nac from Libros l
inner join Prestamos p on P.IDLibro = L.ID
inner join Socios s on s.ID = P.IDSocio
where Besteller = 1