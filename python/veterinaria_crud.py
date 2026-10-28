"""
============================================================================
 PROYECTO INTEGRADOR - BASE DE DATOS I
 Sistema de gestion para una veterinaria
 ----------------------------------------------------------------------------
 Integrantes : Maximo Aceituno - Federico Calafiore
 Carrera     : Tecnicatura Superior en Desarrollo de Software
 Espacio     : Practica Profesional I - Base de Datos I
 Docente     : Juan Caballero Gallar
 Ciclo       : 2026
 ----------------------------------------------------------------------------
 Archivo     : veterinaria_crud.py
 Motor ORM   : peewee + PyMySQL
 Base        : veterinaria_integrador (creada por veterinaria_integrador.sql)
 ----------------------------------------------------------------------------
 El CRUD se realiza sobre DOS tablas interrelacionadas:
     propietario (1) ----< (N) mascota
 Se usan ademas las tablas de catalogo especie y raza para respetar la
 clave foranea de mascota.
 ----------------------------------------------------------------------------
 Uso:
     python veterinaria_crud.py --demo
     python veterinaria_crud.py --menu
     python veterinaria_crud.py --check

 Variables de entorno (opcionales):
     VET_DB        nombre de la base      (default: veterinaria_integrador)
     VET_USER      usuario                (default: root)
     VET_PASSWORD  contrasena             (default: vacia)
     VET_HOST      host                   (default: 127.0.0.1)
     VET_PORT      puerto                 (default: 3306)
============================================================================
"""

from __future__ import annotations

import argparse
import os
import sys
from datetime import date, datetime

from peewee import (
    AutoField,
    CharField,
    DateField,
    ForeignKeyField,
    IntegerField,
    JOIN,
    Model,
    MySQLDatabase,
    TextField,
    fn,
)

# ---------------------------------------------------------------------------
# 1. CONFIGURACION DE LA CONEXION
# ---------------------------------------------------------------------------

DB_NAME = os.getenv("VET_DB", "veterinaria_integrador")
DB_USER = os.getenv("VET_USER", "root")
DB_PASSWORD = os.getenv("VET_PASSWORD", "")
DB_HOST = os.getenv("VET_HOST", "127.0.0.1")
DB_PORT = int(os.getenv("VET_PORT", "3306"))

db = MySQLDatabase(
    DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD,
    host=DB_HOST,
    port=DB_PORT,
    charset="utf8mb4",
)


# ---------------------------------------------------------------------------
# 2. MODELOS PEEWEE
# ---------------------------------------------------------------------------

class BaseModel(Model):
    class Meta:
        database = db


class Especie(BaseModel):
    id_especie = AutoField()
    nombre_especie = CharField(max_length=40, unique=True)

    class Meta:
        table_name = "especie"


class Raza(BaseModel):
    id_raza = AutoField()
    nombre_raza = CharField(max_length=60)
    id_especie = ForeignKeyField(
        Especie, backref="razas", column_name="id_especie", on_delete="RESTRICT"
    )

    class Meta:
        table_name = "raza"
        indexes = ((("id_especie", "nombre_raza"), True),)


class Propietario(BaseModel):
    id_propietario = AutoField()
    nombre = CharField(max_length=50)
    apellido = CharField(max_length=50)
    dni = CharField(max_length=10, unique=True)
    telefono = CharField(max_length=20)
    email = CharField(max_length=100, unique=True, null=True)
    direccion = CharField(max_length=150, null=True)

    class Meta:
        table_name = "propietario"

    def __str__(self) -> str:
        return f"{self.nombre} {self.apellido} (DNI {self.dni})"


class Mascota(BaseModel):
    id_mascota = AutoField()
    nombre = CharField(max_length=50)
    fecha_nacimiento = DateField()
    sexo = CharField(max_length=10)
    antecedentes_clinicos = TextField(null=True)
    id_propietario = ForeignKeyField(
        Propietario,
        backref="mascotas",
        column_name="id_propietario",
        on_delete="RESTRICT",
    )
    id_raza = ForeignKeyField(
        Raza, backref="mascotas", column_name="id_raza", on_delete="RESTRICT"
    )

    class Meta:
        table_name = "mascota"

    def __str__(self) -> str:
        return f"{self.nombre} ({self.sexo})"


# ---------------------------------------------------------------------------
# 3. FUNCIONES DEL CRUD
# ---------------------------------------------------------------------------

def listar_propietarios() -> list[Propietario]:
    """SELECT con LEFT JOIN + GROUP BY: duenios y cantidad de mascotas."""
    consulta = (
        Propietario
        .select(
            Propietario,
            fn.COUNT(Mascota.id_mascota).alias("total_mascotas"),
        )
        .join(Mascota, JOIN.LEFT_OUTER, on=(Mascota.id_propietario == Propietario.id_propietario))
        .group_by(Propietario.id_propietario)
        .order_by(Propietario.apellido, Propietario.nombre)
    )
    return list(consulta)


def buscar_por_patron(texto: str) -> list[Mascota]:
    """SELECT con LIKE: busca por nombre de mascota o apellido del duenio."""
    patron = f"%{texto}%"
    return list(
        Mascota
        .select(Mascota, Propietario)
        .join(Propietario)
        .where((Mascota.nombre ** patron) | (Propietario.apellido ** patron))
        .order_by(Propietario.apellido, Mascota.nombre)
    )


def obtener_raza(nombre_raza: str) -> Raza:
    """Devuelve una raza por nombre o la primera disponible."""
    raza = Raza.get_or_none(Raza.nombre_raza == nombre_raza)
    if raza is None:
        raza = Raza.select().order_by(Raza.id_raza).first()
    if raza is None:
        raise RuntimeError(
            "No hay razas cargadas. Ejecute primero veterinaria_integrador.sql"
        )
    return raza


def crear_propietario_con_mascota(
    nombre: str,
    apellido: str,
    dni: str,
    telefono: str,
    email: str,
    direccion: str,
    mascota_nombre: str,
    fecha_nacimiento: date,
    sexo: str,
    raza_nombre: str = "Mestizo",
) -> tuple[Propietario, Mascota]:
    """INSERT en 2 tablas relacionadas dentro de una transaccion."""
    raza = obtener_raza(raza_nombre)
    with db.atomic():
        duenio = Propietario.create(
            nombre=nombre,
            apellido=apellido,
            dni=dni,
            telefono=telefono,
            email=email,
            direccion=direccion,
        )
        mascota = Mascota.create(
            nombre=mascota_nombre,
            fecha_nacimiento=fecha_nacimiento,
            sexo=sexo,
            antecedentes_clinicos="Registro creado desde peewee.",
            id_propietario=duenio,
            id_raza=raza,
        )
    return duenio, mascota


def actualizar_duenio_y_mascota(
    id_propietario: int,
    id_mascota: int,
    nuevo_telefono: str,
    nuevo_nombre_mascota: str,
) -> tuple[Propietario, Mascota]:
    """UPDATE en 2 tablas relacionadas dentro de una transaccion."""
    with db.atomic():
        duenio = Propietario.get_by_id(id_propietario)
        duenio.telefono = nuevo_telefono
        duenio.save()

        mascota = Mascota.get(
            (Mascota.id_mascota == id_mascota)
            & (Mascota.id_propietario == id_propietario)
        )
        mascota.nombre = nuevo_nombre_mascota
        mascota.save()
    return duenio, mascota


def eliminar_mascota_y_duenio(id_propietario: int, id_mascota: int) -> tuple[bool, bool]:
    """
    DELETE en 2 tablas relacionadas.
    Primero se elimina la mascota; si el duenio queda sin mascotas, se elimina
    tambien el duenio. Todo dentro de una transaccion.
    """
    with db.atomic():
        mascota = Mascota.get(
            (Mascota.id_mascota == id_mascota)
            & (Mascota.id_propietario == id_propietario)
        )
        mascota.delete_instance()

        quedan = (
            Mascota.select()
            .where(Mascota.id_propietario == id_propietario)
            .count()
        )
        duenio_eliminado = False
        if quedan == 0:
            Propietario.delete_by_id(id_propietario)
            duenio_eliminado = True
    return True, duenio_eliminado


# ---------------------------------------------------------------------------
# 4. PRESENTACION EN CONSOLA
# ---------------------------------------------------------------------------

def imprimir_tabla_propietarios() -> None:
    print("\n--- Propietarios y cantidad de mascotas -------------------------")
    print(f"{'ID':>3}  {'Apellido y nombre':<32} {'DNI':<10} {'Telefono':<18} {'Mascotas':>8}")
    print("-" * 78)
    for p in listar_propietarios():
        print(
            f"{p.id_propietario:>3}  "
            f"{(p.apellido + ', ' + p.nombre):<32} "
            f"{p.dni:<10} "
            f"{p.telefono:<18} "
            f"{p.total_mascotas:>8}"
        )
    print("-" * 78)


def imprimir_mascotas(mascotas: list[Mascota]) -> None:
    print("\n--- Mascotas encontradas ---------------------------------------")
    if not mascotas:
        print("Sin resultados.")
        return
    print(f"{'ID':>3}  {'Mascota':<18} {'Nacimiento':<12} {'Sexo':<8} {'Duenio':<28}")
    print("-" * 78)
    for m in mascotas:
        print(
            f"{m.id_mascota:>3}  "
            f"{m.nombre:<18} "
            f"{m.fecha_nacimiento.isoformat():<12} "
            f"{m.sexo:<8} "
            f"{(m.id_propietario.apellido + ', ' + m.id_propietario.nombre):<28}"
        )
    print("-" * 78)


# ---------------------------------------------------------------------------
# 5. MODO DEMO (ejecuta las 4 operaciones sin pedir datos)
# ---------------------------------------------------------------------------

def demo() -> None:
    sufijo = datetime.now().strftime("%H%M%S")
    dni = f"9{sufijo}"

    print("=" * 78)
    print(" DEMO CRUD - peewee sobre propietario y mascota")
    print("=" * 78)

    # SELECT
    imprimir_tabla_propietarios()

    # INSERT
    print("\n[INSERT] Alta de propietario + mascota en una transaccion...")
    duenio, mascota = crear_propietario_con_mascota(
        nombre="Sofia",
        apellido="Herrera",
        dni=dni,
        telefono="2615550106",
        email=f"sofia.herrera.{sufijo}@mail.com",
        direccion="Rivadavia 456",
        mascota_nombre="Chispita",
        fecha_nacimiento=date(2024, 2, 1),
        sexo="Hembra",
        raza_nombre="Mestizo",
    )
    print(f"  OK -> propietario #{duenio.id_propietario}: {duenio}")
    print(f"  OK -> mascota     #{mascota.id_mascota}: {mascota}")

    # SELECT con JOIN
    print("\n[SELECT] Verificacion del alta con JOIN:")
    imprimir_mascotas(
        list(
            Mascota.select(Mascota, Propietario)
            .join(Propietario)
            .where(Propietario.dni == dni)
        )
    )

    # UPDATE
    print("\n[UPDATE] Modificacion de telefono y nombre de la mascota...")
    duenio, mascota = actualizar_duenio_y_mascota(
        id_propietario=duenio.id_propietario,
        id_mascota=mascota.id_mascota,
        nuevo_telefono="2615559999",
        nuevo_nombre_mascota="Chispa",
    )
    print(f"  OK -> {duenio} | telefono: {duenio.telefono}")
    print(f"  OK -> mascota: {mascota.nombre}")

    # SELECT con LIKE
    print("\n[SELECT] Busqueda con LIKE por el apellido 'Herrera':")
    imprimir_mascotas(buscar_por_patron("Herrera"))

    # DELETE
    print("\n[DELETE] Baja de la mascota y del propietario de prueba...")
    ok_mascota, ok_duenio = eliminar_mascota_y_duenio(
        id_propietario=duenio.id_propietario,
        id_mascota=mascota.id_mascota,
    )
    print(f"  OK -> mascota eliminada: {ok_mascota}")
    print(f"  OK -> propietario eliminado: {ok_duenio}")

    # Estado final
    imprimir_tabla_propietarios()
    print("\nDemo finalizada correctamente.")


# ---------------------------------------------------------------------------
# 6. MODO INTERACTIVO
# ---------------------------------------------------------------------------

def pedir(texto: str, default: str | None = None) -> str:
    valor = input(f"{texto}: ").strip()
    if not valor and default is not None:
        return default
    return valor


def menu() -> None:
    while True:
        print(
            "\n===== CRUD VETERINARIA (peewee) =====\n"
            "1. Listar propietarios y sus mascotas\n"
            "2. Alta de propietario + mascota\n"
            "3. Modificar telefono y nombre de mascota\n"
            "4. Baja de mascota (y duenio si queda sin mascotas)\n"
            "5. Buscar por nombre o apellido (LIKE)\n"
            "0. Salir"
        )
        opcion = pedir("Opcion", "0")

        if opcion == "1":
            imprimir_tabla_propietarios()

        elif opcion == "2":
            nombre = pedir("Nombre del duenio")
            apellido = pedir("Apellido del duenio")
            dni = pedir("DNI")
            telefono = pedir("Telefono")
            email = pedir("Email")
            direccion = pedir("Direccion", "")
            mascota_nombre = pedir("Nombre de la mascota")
            nacimiento = pedir("Fecha de nacimiento (AAAA-MM-DD)")
            sexo = pedir("Sexo (Macho/Hembra/Otro)", "Otro")
            raza = pedir("Raza", "Mestizo")
            try:
                duenio, mascota = crear_propietario_con_mascota(
                    nombre, apellido, dni, telefono, email, direccion,
                    mascota_nombre, date.fromisoformat(nacimiento), sexo, raza,
                )
                print(f"Alta OK: {duenio} / {mascota}")
            except Exception as exc:  # noqa: BLE001
                print(f"ERROR: {exc}")

        elif opcion == "3":
            try:
                id_duenio = int(pedir("ID del propietario"))
                id_mascota = int(pedir("ID de la mascota"))
                telefono = pedir("Nuevo telefono")
                nombre = pedir("Nuevo nombre de la mascota")
                duenio, mascota = actualizar_duenio_y_mascota(
                    id_duenio, id_mascota, telefono, nombre
                )
                print(f"Actualizado: {duenio} / {mascota}")
            except Exception as exc:  # noqa: BLE001
                print(f"ERROR: {exc}")

        elif opcion == "4":
            try:
                id_duenio = int(pedir("ID del propietario"))
                id_mascota = int(pedir("ID de la mascota"))
                ok_m, ok_d = eliminar_mascota_y_duenio(id_duenio, id_mascota)
                print(f"Mascota eliminada: {ok_m} | Propietario eliminado: {ok_d}")
            except Exception as exc:  # noqa: BLE001
                print(f"ERROR: {exc}")

        elif opcion == "5":
            texto = pedir("Texto a buscar")
            imprimir_mascotas(buscar_por_patron(texto))

        elif opcion == "0":
            print("Fin.")
            break

        else:
            print("Opcion invalida.")


# ---------------------------------------------------------------------------
# 7. MAIN
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description="CRUD de la veterinaria con peewee")
    grupo = parser.add_mutually_exclusive_group()
    grupo.add_argument("--demo", action="store_true", help="ejecuta una demo automatica")
    grupo.add_argument("--menu", action="store_true", help="abre el menu interactivo")
    grupo.add_argument("--check", action="store_true", help="prueba la conexion")
    args = parser.parse_args()

    try:
        db.connect(reuse_if_open=True)
        db.execute_sql("SELECT 1")
    except Exception as exc:  # noqa: BLE001
        print("No se pudo conectar a MySQL.")
        print(f"  Base: {DB_NAME} | Usuario: {DB_USER} | Host: {DB_HOST}:{DB_PORT}")
        print(f"  Detalle: {exc}")
        print("\nSugerencias:")
        print("  1. Verificar que el servicio MySQL este iniciado.")
        print("  2. Ejecutar primero sql/veterinaria_integrador.sql.")
        print("  3. Definir VET_PASSWORD si el usuario root tiene contrasena.")
        return 1

    print(f"Conectado a {DB_HOST}:{DB_PORT}/{DB_NAME} como {DB_USER}")

    try:
        if args.check:
            print("Conexion OK.")
        elif args.menu:
            menu()
        else:
            demo()
    finally:
        db.close()

    return 0


if __name__ == "__main__":
    sys.exit(main())
