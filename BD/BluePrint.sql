create database BluePrint
go
use Blueprint
go
create Table TipoClientes(
	ID int primary key identity(1,1) not null,
	Tipo varchar(50) not null
)
go
create table Clientes(
	ID int primary key identity(1,1) not null,
	RazonSocial varchar(50) not null,
	cuit varchar(11) unique not null,
	IDtipoCliente int foreign key references TipoClientes(ID) not null,
	Email varchar(50) null,
	Telefono varchar(13) null,
	Celular varchar(13) null,
)
go
create table Proyectos(
	ID int primary key identity(1,1) not null,
	IDCliente int foreign key references Clientes(ID) not null,
	Nombre varchar(50) not null,
	Descripcion varchar(512) null,
	FechaInicio date not null,
	FechaFin date null,
	Costo money check(Costo>0) not null,
	Estado bit not null,
	check (FechaInicio<FechaFin)
)
go
create table Pais(
	ID int primary key identity(1,1) not null,
	Pais varchar(50) not null
)
go
create table Ciudad(
	ID int primary key identity(1,1) not null,
	IDPais int foreign key references Pais(ID) not null,
	Ciudad varchar(50) not null
)
go
create table Modulo(
	ID int primary key identity(1,1) not null,
	IDProyecto int foreign key references Proyectos(ID) not null,
	Nombre varchar(50) not null,
	Descripcion varchar(512) null,
	Costo money check(Costo>0) not null,
	HorasEstimadas int check(HorasEstimadas>0) not null,
	FechaIncio date null,
	FechaFin date null,
	FechaEstimadaFin date null,
	check(FechaIncio<= FechaFin),
	check(FechaIncio<= FechaEstimadaFin)
)
go
create table Colaborador(
	ID int primary key identity(1,1) not null,
	Nombre varchar(50) not null,
	Apellido varchar(50) not null,
	Email varchar(50) null,
	Celular varchar(13) null,
	check (Email != null or Celular != null),
	FechaNacimiento date not null,
	Domicilio varchar(50) not null,
	IDCiudad int foreign key references Ciudad(ID) not null,
	Tipo char(1) check(Tipo='i' or tipo='e')
)
go
alter table Clientes
	ADD IDCiudad int not null foreign key references Ciudad(ID)
go
create table TipoTareas(
	ID int primary key identity(1,1) not null,
	tipo varchar(50) not null
)
go
create table Tareas(
	ID int primary key identity(1,1) not null,
	IDModulo int foreign key references Modulo(ID) not null,
	IDTipoTare int foreign key references TipoTareas(ID) not null,
	FechaInicio date null,
	FechaFin date null,
	Estado bit not null,
	check(FechaInicio<=FechaFin)
)
go
create table Colaboracion(
	IDTarea int foreign key references Tareas(ID) not null,
	IDColaborador int foreign key references Colaborador(ID) not null,
	primary key (IDTarea, IDColaborador),
	CantidadHoras int check(CantidadHoras>0) not null,
	ValorHora money check(ValorHora>0) not null,
	Estado bit not null
)

