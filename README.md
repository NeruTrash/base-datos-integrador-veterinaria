# Sistema de gestión para una veterinaria

**Proyecto Integrador — Base de Datos I**
Tecnicatura Superior en Desarrollo de Software · Ciclo lectivo 2026

**Integrantes:** Máximo Aceituno y Federico Calafiore
**Docente:** Juan Caballero Gallar

---

## Descripción

Base de datos relacional en MySQL para la gestión de una veterinaria. El modelo cubre
propietarios, mascotas, especies, razas, veterinarios, consultas, diagnósticos, tratamientos,
vacunaciones, cirugías e internaciones. Incluye un script SQL autocontenido (DDL, DCL, DML,
vistas, triggers y transacciones) y un CRUD en Python con el ORM **peewee** sobre las tablas
relacionadas `propietario` y `mascota`.

La base se denomina **`veterinaria_integrador`** para no modificar la base `veterinaria_db`
utilizada en los trabajos prácticos anteriores.

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Motor de base de datos | MySQL 26.7 (InnoDB, utf8mb4) |
| Cliente SQL | MySQL Workbench 8.0 CE |
| Lenguaje | Python 3.12 |
| ORM | peewee 3.17+ |
| Driver | PyMySQL 1.1+ |
| Cifrado | cryptography 42+ |
| Diagramas | Graphviz / @viz-js/viz + Sharp |
| Documento | HTML5 + CSS3 + Edge headless |

## Estructura del repositorio

```
base-datos-integrador-veterinaria/
|-- README.md
|-- sql/
|   +-- veterinaria_integrador.sql
|-- python/
|   |-- veterinaria_crud.py
|   +-- requirements.txt
|-- img/
|   |-- modelo_conceptual_chen.png
|   |-- modelo_conceptual_atributos.png
|   |-- modelo_logico_pata_gallo.png
|   +-- modelo_fisico_eer.png
+-- docs/
    |-- TP_Integrador_Base_de_Datos.pdf
    +-- TP_Integrador_Base_de_Datos.html
```

## Requisitos

- MySQL 8.0 o superior (probado en MySQL 26.7).
- Python 3.12 o superior.
- `pip` para instalar las dependencias.

## Ejecución

### 1. Crear y poblar la base

```bash
mysql -u root -p < sql/veterinaria_integrador.sql
```

El script crea la base `veterinaria_integrador`, las once tablas, los triggers, los datos de
prueba, las cinco vistas, los cinco usuarios y ejecuta las transacciones de demostración.

> **Atención:** el script comienza con `DROP DATABASE IF EXISTS veterinaria_integrador`.
> Si se vuelve a ejecutar, se elimina y se recrea la base con los datos de prueba. No afecta
> a `veterinaria_db`.

### 2. Instalar dependencias de Python

```bash
pip install -r python/requirements.txt
```

### 3. Configurar la conexión (opcional)

| Variable | Valor por defecto |
|---|---|
| `VET_DB` | `veterinaria_integrador` |
| `VET_USER` | `root` |
| `VET_PASSWORD` | vacío |
| `VET_HOST` | `127.0.0.1` |
| `VET_PORT` | `3306` |

Ejemplo en PowerShell:

```powershell
$env:VET_USER = "root"
$env:VET_PASSWORD = "tu_contraseña"
$env:VET_DB = "veterinaria_integrador"
```

### 4. Ejecutar el CRUD

```bash
python python/veterinaria_crud.py --check   # verifica la conexión
python python/veterinaria_crud.py --demo    # ejecuta las cuatro operaciones
python python/veterinaria_crud.py --menu    # menú interactivo
```

## Usuarios de base de datos

| Usuario | Rol | Permisos principales |
|---|---|---|
| `admin_vet` | Administrador | `ALL PRIVILEGES` con `GRANT OPTION` |
| `recepcion_vet` | Recepción | `SELECT`, `INSERT`, `UPDATE` en propietario, mascota y consulta |
| `veterinario_vet` | Veterinario | `SELECT` general; `INSERT`/`UPDATE` en consulta, diagnóstico y tratamiento |
| `asistente_vet` | Asistente | `SELECT` general; `INSERT`/`UPDATE` en vacunación, cirugía e internación |
| `consulta_vet` | Consulta pública | `SELECT` solo sobre las cinco vistas |

Las contraseñas incluidas en el script son de ejemplo académico y deben reemplazarse en un
entorno real.

## Documentación

El informe técnico completo está en
[`docs/TP_Integrador_Base_de_Datos.pdf`](docs/TP_Integrador_Base_de_Datos.pdf). Incluye portada,
índice, stack tecnológico, modelo conceptual Chen, modelo lógico pata de gallo, modelo físico EER,
normalización, diccionario de datos, implementación SQL, CRUD en Python, pruebas, repositorio y
retrospectiva.

## Estado de validación

- Script SQL ejecutado de principio a fin sin errores en MySQL 26.7.
- Once tablas, cinco vistas y cinco usuarios creados correctamente.
- Restricciones verificadas: FK (`ERROR 1452`), `RESTRICT` (`ERROR 1451`), `CHECK` (`ERROR 3819`),
  trigger de fecha (`ERROR 1644`) y unicidad 1:1 (`ERROR 1062`).
- CRUD de Python probado con `--demo`: alta, consulta, modificación y baja.
- Conteo final: 4 especies, 9 razas, 6 propietarios, 9 mascotas, 5 veterinarios, 9 consultas,
  9 diagnósticos, 11 tratamientos, 8 vacunaciones, 4 cirugías y 3 internaciones.

## Repositorio

Repositorio público: `https://github.com/NeruTrash/base-datos-integrador-veterinaria`

## Autores

- Máximo Aceituno
- Federico Calafiore
