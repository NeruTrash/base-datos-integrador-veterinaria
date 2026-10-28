-- ============================================================================
-- PROYECTO INTEGRADOR - BASE DE DATOS I
-- Sistema de gestion para una veterinaria
-- ----------------------------------------------------------------------------
-- Integrantes : Maximo Aceituno - Federico Calafiore
-- Carrera     : Tecnicatura Superior en Desarrollo de Software
-- Espacio     : Practica Profesional I - Base de Datos I
-- Docente     : Juan Caballero Gallar
-- Ciclo       : 2026
-- Motor       : MySQL 26.7 (compatible con MySQL 8.0+)
-- Base        : veterinaria_integrador
-- ----------------------------------------------------------------------------
-- Contenido:
--   0. Creacion de la base
--   1. DDL  - Tablas, claves y restricciones
--   2. Triggers de validacion
--   3. Datos de prueba (poblado)
--   4. Vistas
--   5. DCL  - Usuarios y permisos
--   6. DML  - Transacciones, COMMIT, ROLLBACK y funciones nativas
--   7. Consultas de verificacion (JOIN, GROUP BY, LIKE, subconsultas)
--   8. Verificacion final
-- ----------------------------------------------------------------------------
-- NOTA: se usa una base NUEVA (veterinaria_integrador) para no pisar la base
--       veterinaria_db del TP5/TP6. Si se desea reutilizar el nombre anterior,
--       basta con cambiar el nombre en las dos lineas siguientes.
-- ============================================================================

DROP DATABASE IF EXISTS veterinaria_integrador;
CREATE DATABASE veterinaria_integrador
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE veterinaria_integrador;

SET NAMES utf8mb4;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';


-- ============================================================================
-- 1. DDL - TABLAS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1 especie
-- ----------------------------------------------------------------------------
CREATE TABLE especie (
    id_especie      INT UNSIGNED AUTO_INCREMENT,
    nombre_especie  VARCHAR(40)  NOT NULL,

    PRIMARY KEY (id_especie),
    UNIQUE KEY uq_especie_nombre (nombre_especie)
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- 1.2 raza
-- ----------------------------------------------------------------------------
CREATE TABLE raza (
    id_raza       INT UNSIGNED AUTO_INCREMENT,
    nombre_raza   VARCHAR(60)  NOT NULL,
    id_especie    INT UNSIGNED NOT NULL,

    PRIMARY KEY (id_raza),
    UNIQUE KEY uq_raza_especie_nombre (id_especie, nombre_raza),
    KEY idx_raza_especie (id_especie),
    CONSTRAINT fk_raza_especie
        FOREIGN KEY (id_especie) REFERENCES especie (id_especie)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- 1.3 propietario
-- ----------------------------------------------------------------------------
CREATE TABLE propietario (
    id_propietario  INT UNSIGNED AUTO_INCREMENT,
    nombre          VARCHAR(50)  NOT NULL,
    apellido        VARCHAR(50)  NOT NULL,
    dni             VARCHAR(10)  NOT NULL,
    telefono        VARCHAR(20)  NOT NULL,
    email           VARCHAR(100),
    direccion       VARCHAR(150),
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id_propietario),
    UNIQUE KEY uq_propietario_dni (dni),
    UNIQUE KEY uq_propietario_email (email),
    KEY idx_propietario_apellido (apellido)
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- 1.4 mascota
--     La especie se obtiene a traves de la raza (raza.id_especie), de modo
--     que no se repite el dato y se mantiene la Tercera Forma Normal.
-- ----------------------------------------------------------------------------
CREATE TABLE mascota (
    id_mascota              INT UNSIGNED AUTO_INCREMENT,
    nombre                  VARCHAR(50)  NOT NULL,
    fecha_nacimiento        DATE         NOT NULL,
    sexo                    ENUM('Macho', 'Hembra', 'Otro') NOT NULL,
    antecedentes_clinicos   TEXT,
    id_propietario          INT UNSIGNED NOT NULL,
    id_raza                 INT UNSIGNED NOT NULL,

    PRIMARY KEY (id_mascota),
    KEY idx_mascota_propietario (id_propietario),
    KEY idx_mascota_raza (id_raza),
    CONSTRAINT fk_mascota_propietario
        FOREIGN KEY (id_propietario) REFERENCES propietario (id_propietario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_mascota_raza
        FOREIGN KEY (id_raza) REFERENCES raza (id_raza)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- 1.5 veterinario
-- ----------------------------------------------------------------------------
CREATE TABLE veterinario (
    id_veterinario  INT UNSIGNED AUTO_INCREMENT,
    nombre          VARCHAR(50)  NOT NULL,
    apellido        VARCHAR(50)  NOT NULL,
    matricula       VARCHAR(30)  NOT NULL,
    especialidad    VARCHAR(100),
    telefono        VARCHAR(20),
    email           VARCHAR(100),

    PRIMARY KEY (id_veterinario),
    UNIQUE KEY uq_veterinario_matricula (matricula),
    UNIQUE KEY uq_veterinario_email (email)
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- 1.6 consulta
-- ----------------------------------------------------------------------------
CREATE TABLE consulta (
    id_consulta     INT UNSIGNED AUTO_INCREMENT,
    fecha           DATETIME     NOT NULL,
    motivo          VARCHAR(255) NOT NULL,
    id_mascota      INT UNSIGNED NOT NULL,
    id_veterinario  INT UNSIGNED NOT NULL,

    PRIMARY KEY (id_consulta),
    KEY idx_consulta_fecha (fecha),
    KEY idx_consulta_mascota (id_mascota),
    KEY idx_consulta_veterinario (id_veterinario),
    CONSTRAINT fk_consulta_mascota
        FOREIGN KEY (id_mascota) REFERENCES mascota (id_mascota)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_consulta_veterinario
        FOREIGN KEY (id_veterinario) REFERENCES veterinario (id_veterinario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- 1.7 diagnostico  (relacion 1:1 con consulta)
-- ----------------------------------------------------------------------------
CREATE TABLE diagnostico (
    id_diagnostico  INT UNSIGNED AUTO_INCREMENT,
    descripcion     VARCHAR(500) NOT NULL,
    id_consulta     INT UNSIGNED NOT NULL,

    PRIMARY KEY (id_diagnostico),
    UNIQUE KEY uq_diagnostico_consulta (id_consulta),
    CONSTRAINT fk_diagnostico_consulta
        FOREIGN KEY (id_consulta) REFERENCES consulta (id_consulta)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- 1.8 tratamiento  (relacion 1:N con consulta)
-- ----------------------------------------------------------------------------
CREATE TABLE tratamiento (
    id_tratamiento  INT UNSIGNED AUTO_INCREMENT,
    medicamento     VARCHAR(100) NOT NULL,
    descripcion     VARCHAR(255),
    duracion_dias   INT UNSIGNED NOT NULL,
    id_consulta     INT UNSIGNED NOT NULL,

    PRIMARY KEY (id_tratamiento),
    KEY idx_tratamiento_consulta (id_consulta),
    CONSTRAINT fk_tratamiento_consulta
        FOREIGN KEY (id_consulta) REFERENCES consulta (id_consulta)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT chk_tratamiento_duracion CHECK (duracion_dias > 0)
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- 1.9 vacunacion
-- ----------------------------------------------------------------------------
CREATE TABLE vacunacion (
    id_vacunacion   INT UNSIGNED AUTO_INCREMENT,
    nombre_vacuna   VARCHAR(100) NOT NULL,
    fecha           DATE         NOT NULL,
    proxima_dosis   DATE,
    id_mascota      INT UNSIGNED NOT NULL,
    id_veterinario  INT UNSIGNED NOT NULL,

    PRIMARY KEY (id_vacunacion),
    KEY idx_vacunacion_mascota (id_mascota),
    KEY idx_vacunacion_veterinario (id_veterinario),
    KEY idx_vacunacion_proxima (proxima_dosis),
    CONSTRAINT fk_vacunacion_mascota
        FOREIGN KEY (id_mascota) REFERENCES mascota (id_mascota)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_vacunacion_veterinario
        FOREIGN KEY (id_veterinario) REFERENCES veterinario (id_veterinario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_vacunacion_dosis CHECK (proxima_dosis IS NULL OR proxima_dosis > fecha)
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- 1.10 cirugia
-- ----------------------------------------------------------------------------
CREATE TABLE cirugia (
    id_cirugia      INT UNSIGNED AUTO_INCREMENT,
    tipo            VARCHAR(100) NOT NULL,
    fecha           DATE         NOT NULL,
    descripcion     VARCHAR(500),
    id_mascota      INT UNSIGNED NOT NULL,
    id_veterinario  INT UNSIGNED NOT NULL,

    PRIMARY KEY (id_cirugia),
    KEY idx_cirugia_mascota (id_mascota),
    KEY idx_cirugia_veterinario (id_veterinario),
    KEY idx_cirugia_fecha (fecha),
    CONSTRAINT fk_cirugia_mascota
        FOREIGN KEY (id_mascota) REFERENCES mascota (id_mascota)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_cirugia_veterinario
        FOREIGN KEY (id_veterinario) REFERENCES veterinario (id_veterinario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- 1.11 internacion
-- ----------------------------------------------------------------------------
CREATE TABLE internacion (
    id_internacion  INT UNSIGNED AUTO_INCREMENT,
    fecha_ingreso   DATETIME     NOT NULL,
    fecha_egreso    DATETIME,
    motivo          VARCHAR(255) NOT NULL,
    id_mascota      INT UNSIGNED NOT NULL,
    id_veterinario  INT UNSIGNED NOT NULL,

    PRIMARY KEY (id_internacion),
    KEY idx_internacion_mascota (id_mascota),
    KEY idx_internacion_veterinario (id_veterinario),
    KEY idx_internacion_egreso (fecha_egreso),
    CONSTRAINT fk_internacion_mascota
        FOREIGN KEY (id_mascota) REFERENCES mascota (id_mascota)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_internacion_veterinario
        FOREIGN KEY (id_veterinario) REFERENCES veterinario (id_veterinario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_internacion_fechas CHECK (fecha_egreso IS NULL OR fecha_egreso >= fecha_ingreso)
) ENGINE = InnoDB;


-- ============================================================================
-- 2. TRIGGERS DE VALIDACION
--    MySQL no permite CURDATE() dentro de un CHECK, por eso la validacion de
--    fechas de nacimiento se resuelve con triggers.
-- ============================================================================

DROP TRIGGER IF EXISTS trg_mascota_fecha_nac_bi;
DROP TRIGGER IF EXISTS trg_mascota_fecha_nac_bu;

DELIMITER $$

CREATE TRIGGER trg_mascota_fecha_nac_bi
BEFORE INSERT ON mascota
FOR EACH ROW
BEGIN
    IF NEW.fecha_nacimiento > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La fecha de nacimiento no puede ser futura';
    END IF;
END$$

CREATE TRIGGER trg_mascota_fecha_nac_bu
BEFORE UPDATE ON mascota
FOR EACH ROW
BEGIN
    IF NEW.fecha_nacimiento > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La fecha de nacimiento no puede ser futura';
    END IF;
END$$

DELIMITER ;


-- ============================================================================
-- 3. DATOS DE PRUEBA
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 Especies y razas
-- ----------------------------------------------------------------------------
INSERT INTO especie (id_especie, nombre_especie) VALUES
    (1, 'Perro'),
    (2, 'Gato'),
    (3, 'Conejo'),
    (4, 'Ave');

INSERT INTO raza (id_raza, nombre_raza, id_especie) VALUES
    (1, 'Labrador',        1),
    (2, 'Caniche',         1),
    (3, 'Bulldog',         1),
    (4, 'Mestizo',         1),
    (5, 'Siames',          2),
    (6, 'Comun europeo',   2),
    (7, 'Persa',           2),
    (8, 'Cabeza de leon',  3),
    (9, 'Canario',         4);

-- ----------------------------------------------------------------------------
-- 3.2 Propietarios
-- ----------------------------------------------------------------------------
INSERT INTO propietario
    (id_propietario, nombre, apellido, dni, telefono, email, direccion)
VALUES
    (1, 'Lucia',   'Fernandez', '30111222', '2615550101', 'lucia.fernandez@mail.com', 'San Martin 123, Godoy Cruz'),
    (2, 'Martin',  'Gomez',     '28444555', '2615550102', 'martin.gomez@mail.com',    'Belgrano 456, Godoy Cruz'),
    (3, 'Carla',   'Rodriguez', '32666777', '2615550103', 'carla.rodriguez@mail.com', 'Sarmiento 789, Guaymallen'),
    (4, 'Diego',   'Sosa',      '35777888', '2615550104', 'diego.sosa@mail.com',      'Rivadavia 1010, Las Heras'),
    (5, 'Valeria', 'Nunez',     '29888999', '2615550105', 'valeria.nunez@mail.com',   'Mitre 2020, Ciudad');

-- ----------------------------------------------------------------------------
-- 3.3 Mascotas (8)
-- ----------------------------------------------------------------------------
INSERT INTO mascota
    (id_mascota, nombre, fecha_nacimiento, sexo, antecedentes_clinicos, id_propietario, id_raza)
VALUES
    (1, 'Firulais', '2019-03-12', 'Macho',  'Alergia estacional. Displasia leve de cadera.', 1, 1),
    (2, 'Michi',    '2021-07-01', 'Hembra', 'Sin antecedentes relevantes.',                  1, 5),
    (3, 'Luna',     '2018-11-23', 'Hembra', 'Cesarea en 2026. Sobrepeso.',                   2, 2),
    (4, 'Rocky',    '2020-05-09', 'Macho',  'Tumor extirpado en 2026.',                      3, 3),
    (5, 'Nala',     '2022-02-14', 'Hembra', 'Dermatitis atopica.',                           4, 6),
    (6, 'Coco',     '2023-01-30', 'Macho',  'Sin consultas registradas.',                    5, 8),
    (7, 'Toby',     '2024-04-18', 'Macho',  'Vacunacion al dia.',                            5, 4),
    (8, 'Kiara',    '2021-09-05', 'Hembra', 'Alopecia felina en tratamiento.',               2, 7);

-- ----------------------------------------------------------------------------
-- 3.4 Veterinarios (5, uno sin consultas para probar LEFT JOIN)
-- ----------------------------------------------------------------------------
INSERT INTO veterinario
    (id_veterinario, nombre, apellido, matricula, especialidad, telefono, email)
VALUES
    (1, 'Ana',    'Paredes', 'MP-1001', 'Clinica general',        '2614440001', 'ana.paredes@veterinaria.com'),
    (2, 'Raul',   'Benitez', 'MP-1002', 'Dermatologia',           '2614440002', 'raul.benitez@veterinaria.com'),
    (3, 'Julia',  'Molina',  'MP-1003', 'Cardiologia',            '2614440003', 'julia.molina@veterinaria.com'),
    (4, 'Esteban','Ruiz',    'MP-1004', 'Cirugia',                '2614440004', 'esteban.ruiz@veterinaria.com'),
    (5, 'Laura',  'Diaz',    'MP-1005', 'Diagnostico por imagen', '2614440005', 'laura.diaz@veterinaria.com');

-- ----------------------------------------------------------------------------
-- 3.5 Consultas (10)
-- ----------------------------------------------------------------------------
INSERT INTO consulta
    (id_consulta, fecha, motivo, id_mascota, id_veterinario)
VALUES
    (1,  '2026-03-10 09:30:00', 'Control anual',                   1, 1),
    (2,  '2026-04-02 11:00:00', 'Picazon en la piel',              3, 2),
    (3,  '2026-05-15 16:00:00', 'Vomitos',                         2, 1),
    (4,  '2026-06-20 10:15:00', 'Tos persistente',                 4, 3),
    (5,  '2026-07-08 12:00:00', 'Cojera en pata trasera',          1, 1),
    (6,  '2026-08-19 17:30:00', 'Vacunacion anual',                5, 1),
    (7,  '2026-09-05 09:00:00', 'Control de la piel',              3, 2),
    (8,  '2026-10-01 15:00:00', 'Control cardiaco',                4, 3),
    (9,  '2026-10-02 10:00:00', 'Consulta duplicada (error)',      5, 1),
    (10, '2026-10-10 11:30:00', 'Alopecia',                        8, 2);

-- ----------------------------------------------------------------------------
-- 3.6 Diagnosticos (1 por consulta)
-- ----------------------------------------------------------------------------
INSERT INTO diagnostico (id_diagnostico, descripcion, id_consulta) VALUES
    (1,  'Sin hallazgos',                    1),
    (2,  'Dermatitis alergica',              2),
    (3,  'Gastritis leve',                   3),
    (4,  'Soplo cardiaco leve',              4),
    (5,  'Esguince grado 1',                 5),
    (6,  'Paciente sano',                    6),
    (7,  'Mejoria de dermatitis',            7),
    (8,  'Estable',                          8),
    (9,  'Registro duplicado',               9),
    (10, 'Alopecia felina',                 10);

-- ----------------------------------------------------------------------------
-- 3.7 Tratamientos (12)
-- ----------------------------------------------------------------------------
INSERT INTO tratamiento (id_tratamiento, medicamento, descripcion, duracion_dias, id_consulta) VALUES
    (1,  'Desparasitante',        'Antiparasitario interno de amplio espectro',      1,  1),
    (2,  'Antihistaminico',       'Un comprimido cada 12 horas',                    10,  2),
    (3,  'Dieta hipoalergenica',  'Alimento balanceado especial',                   30,  2),
    (4,  'Dieta blanda',          'Arroz y pollo hervido, protector gastrico',       7,  3),
    (5,  'Enalapril',             'Medicacion cardiaca diaria',                     30,  4),
    (6,  'Antiinflamatorio',      'Reposo y antiinflamatorio cada 24 horas',        14,  5),
    (7,  'Vacuna antirrabica',    'Dosis unica anual',                               1,  6),
    (8,  'Shampoo medicado',      'Bano cada 3 dias',                               21,  7),
    (9,  'Enalapril',             'Control cardiaco y ajuste de dosis',             30,  8),
    (10, 'Tratamiento de prueba', 'Cargado por error junto a la consulta 9',         5,  9),
    (11, 'Suplemento dermico',    'Acidos grasos esenciales por 30 dias',           30, 10),
    (12, 'Control de peso',       'Dieta y ejercicio controlado',                   60,  8);

-- ----------------------------------------------------------------------------
-- 3.8 Vacunaciones (8)
-- ----------------------------------------------------------------------------
INSERT INTO vacunacion
    (id_vacunacion, nombre_vacuna, fecha, proxima_dosis, id_mascota, id_veterinario)
VALUES
    (1, 'Antirrabica',     '2026-03-10', '2027-03-10', 1, 1),
    (2, 'Sextuple',        '2026-03-10', '2027-03-10', 1, 1),
    (3, 'Triple felina',   '2026-05-15', '2027-05-15', 2, 1),
    (4, 'Antirrabica',     '2026-09-05', '2027-09-05', 3, 2),
    (5, 'Antirrabica',     '2026-06-20', '2027-06-20', 4, 3),
    (6, 'Triple felina',   '2026-08-19', '2027-08-19', 5, 1),
    (7, 'Sextuple',        '2026-09-20', '2026-11-15', 7, 4),
    (8, 'Triple felina',   '2026-10-10', '2027-10-10', 8, 2);

-- ----------------------------------------------------------------------------
-- 3.9 Cirugias (4)
-- ----------------------------------------------------------------------------
INSERT INTO cirugia
    (id_cirugia, tipo, fecha, descripcion, id_mascota, id_veterinario)
VALUES
    (1, 'Esterilizacion',        '2025-11-10', 'Castracion programada sin complicaciones', 1, 4),
    (2, 'Extraccion de tumor',   '2026-06-25', 'Tumor benigno en flanco derecho',          4, 4),
    (3, 'Cesarea',               '2026-02-14', 'Cesarea de urgencia, 3 cachorros',         3, 4),
    (4, 'Limpieza dental',       '2026-09-12', 'Sarro y gingivitis',                       2, 4);

-- ----------------------------------------------------------------------------
-- 3.10 Internaciones (3, una activa)
-- ----------------------------------------------------------------------------
INSERT INTO internacion
    (id_internacion, fecha_ingreso, fecha_egreso, motivo, id_mascota, id_veterinario)
VALUES
    (1, '2026-06-20 18:00:00', '2026-06-23 10:00:00', 'Postoperatorio de tumor',      4, 3),
    (2, '2026-08-19 19:00:00', '2026-08-21 09:00:00', 'Observacion por vomitos',      5, 1),
    (3, '2026-10-25 08:00:00', NULL,                  'Cojera severa en seguimiento', 1, 1);


-- ============================================================================
-- 4. VISTAS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 4.1 Ficha completa de cada mascota con su duenio
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_ficha_mascota AS
SELECT
    m.id_mascota,
    m.nombre                                        AS mascota,
    e.nombre_especie                                AS especie,
    r.nombre_raza                                   AS raza,
    m.sexo,
    m.fecha_nacimiento,
    TIMESTAMPDIFF(YEAR, m.fecha_nacimiento, CURDATE()) AS edad_anios,
    CONCAT(p.nombre, ' ', p.apellido)               AS duenio,
    p.telefono,
    p.email
FROM mascota m
INNER JOIN raza r        ON r.id_raza = m.id_raza
INNER JOIN especie e     ON e.id_especie = r.id_especie
INNER JOIN propietario p ON p.id_propietario = m.id_propietario;

-- ----------------------------------------------------------------------------
-- 4.2 Historial clinico consolidado (una fila por consulta)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_historial_clinico AS
SELECT
    c.id_consulta,
    c.fecha,
    m.nombre                                        AS mascota,
    e.nombre_especie                                AS especie,
    r.nombre_raza                                   AS raza,
    CONCAT(p.nombre, ' ', p.apellido)               AS duenio,
    p.telefono,
    CONCAT(v.nombre, ' ', v.apellido)               AS veterinario,
    v.especialidad,
    c.motivo,
    d.descripcion                                   AS diagnostico,
    GROUP_CONCAT(
        CONCAT(t.medicamento, ' (', t.duracion_dias, ' dias)')
        ORDER BY t.id_tratamiento
        SEPARATOR '; '
    )                                               AS tratamientos
FROM consulta c
INNER JOIN mascota m       ON m.id_mascota = c.id_mascota
INNER JOIN raza r          ON r.id_raza = m.id_raza
INNER JOIN especie e       ON e.id_especie = r.id_especie
INNER JOIN propietario p   ON p.id_propietario = m.id_propietario
INNER JOIN veterinario v   ON v.id_veterinario = c.id_veterinario
LEFT JOIN diagnostico d    ON d.id_consulta = c.id_consulta
LEFT JOIN tratamiento t    ON t.id_consulta = c.id_consulta
GROUP BY
    c.id_consulta, c.fecha, m.nombre, e.nombre_especie, r.nombre_raza,
    p.nombre, p.apellido, p.telefono, v.nombre, v.apellido, v.especialidad,
    c.motivo, d.descripcion;

-- ----------------------------------------------------------------------------
-- 4.3 Vacunas con proxima dosis en los proximos 60 dias
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_vacunas_pendientes AS
SELECT
    m.nombre                                        AS mascota,
    CONCAT(p.nombre, ' ', p.apellido)               AS duenio,
    p.telefono,
    va.nombre_vacuna,
    va.fecha                                        AS fecha_aplicacion,
    va.proxima_dosis,
    DATEDIFF(va.proxima_dosis, CURDATE())           AS dias_para_proxima_dosis,
    CONCAT(v.nombre, ' ', v.apellido)               AS veterinario
FROM vacunacion va
INNER JOIN mascota m      ON m.id_mascota = va.id_mascota
INNER JOIN propietario p  ON p.id_propietario = m.id_propietario
INNER JOIN veterinario v  ON v.id_veterinario = va.id_veterinario
WHERE va.proxima_dosis IS NOT NULL
  AND va.proxima_dosis <= DATE_ADD(CURDATE(), INTERVAL 60 DAY)
ORDER BY va.proxima_dosis;

-- ----------------------------------------------------------------------------
-- 4.4 Resumen de actividad por veterinario
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_resumen_veterinario AS
SELECT
    v.id_veterinario,
    CONCAT(v.nombre, ' ', v.apellido)               AS veterinario,
    v.especialidad,
    (SELECT COUNT(*) FROM consulta c
      WHERE c.id_veterinario = v.id_veterinario)    AS total_consultas,
    (SELECT COUNT(*) FROM cirugia ci
      WHERE ci.id_veterinario = v.id_veterinario)   AS total_cirugias,
    (SELECT COUNT(*) FROM vacunacion va
      WHERE va.id_veterinario = v.id_veterinario)   AS total_vacunaciones,
    (SELECT COUNT(*) FROM internacion i
      WHERE i.id_veterinario = v.id_veterinario)    AS total_internaciones
FROM veterinario v;

-- ----------------------------------------------------------------------------
-- 4.5 Internaciones activas
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_internaciones_activas AS
SELECT
    i.id_internacion,
    m.nombre                                        AS mascota,
    CONCAT(p.nombre, ' ', p.apellido)               AS duenio,
    p.telefono,
    i.fecha_ingreso,
    DATEDIFF(NOW(), i.fecha_ingreso)                AS dias_internado,
    i.motivo,
    CONCAT(v.nombre, ' ', v.apellido)               AS veterinario
FROM internacion i
INNER JOIN mascota m      ON m.id_mascota = i.id_mascota
INNER JOIN propietario p  ON p.id_propietario = m.id_propietario
INNER JOIN veterinario v  ON v.id_veterinario = i.id_veterinario
WHERE i.fecha_egreso IS NULL
ORDER BY i.fecha_ingreso;


-- ============================================================================
-- 5. DCL - USUARIOS Y PERMISOS
--    Se crean cuentas para cada rol del sistema. Las contrasenas son de
--    ejemplo academico; en produccion deben cambiarse y guardarse de forma
--    segura.
-- ============================================================================

DROP USER IF EXISTS 'admin_vet'@'localhost';
DROP USER IF EXISTS 'recepcion_vet'@'localhost';
DROP USER IF EXISTS 'veterinario_vet'@'localhost';
DROP USER IF EXISTS 'asistente_vet'@'localhost';
DROP USER IF EXISTS 'consulta_vet'@'localhost';

-- 5.1 Administrador: acceso total
CREATE USER 'admin_vet'@'localhost' IDENTIFIED BY 'AdminVet2026!';
GRANT ALL PRIVILEGES ON veterinaria_integrador.* TO 'admin_vet'@'localhost' WITH GRANT OPTION;

-- 5.2 Recepcionista: carga duenios, mascotas y consultas
CREATE USER 'recepcion_vet'@'localhost' IDENTIFIED BY 'RecepVet2026!';
GRANT SELECT, INSERT, UPDATE ON veterinaria_integrador.propietario TO 'recepcion_vet'@'localhost';
GRANT SELECT, INSERT, UPDATE ON veterinaria_integrador.mascota     TO 'recepcion_vet'@'localhost';
GRANT SELECT, INSERT, UPDATE ON veterinaria_integrador.consulta    TO 'recepcion_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.especie       TO 'recepcion_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.raza          TO 'recepcion_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.veterinario   TO 'recepcion_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.diagnostico   TO 'recepcion_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.tratamiento   TO 'recepcion_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.vacunacion    TO 'recepcion_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.cirugia       TO 'recepcion_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.internacion   TO 'recepcion_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.v_ficha_mascota TO 'recepcion_vet'@'localhost';

-- 5.3 Veterinario: consulta todo y carga diagnostico/tratamiento
CREATE USER 'veterinario_vet'@'localhost' IDENTIFIED BY 'VetVet2026!';
GRANT SELECT ON veterinaria_integrador.* TO 'veterinario_vet'@'localhost';
GRANT INSERT, UPDATE ON veterinaria_integrador.consulta    TO 'veterinario_vet'@'localhost';
GRANT INSERT, UPDATE ON veterinaria_integrador.diagnostico TO 'veterinario_vet'@'localhost';
GRANT INSERT, UPDATE ON veterinaria_integrador.tratamiento TO 'veterinario_vet'@'localhost';

-- 5.4 Asistente: vacunacion, cirugia e internacion
CREATE USER 'asistente_vet'@'localhost' IDENTIFIED BY 'AsistVet2026!';
GRANT SELECT ON veterinaria_integrador.* TO 'asistente_vet'@'localhost';
GRANT INSERT, UPDATE ON veterinaria_integrador.vacunacion  TO 'asistente_vet'@'localhost';
GRANT INSERT, UPDATE ON veterinaria_integrador.cirugia     TO 'asistente_vet'@'localhost';
GRANT INSERT, UPDATE ON veterinaria_integrador.internacion TO 'asistente_vet'@'localhost';

-- 5.5 Consulta publica: solo lectura de las vistas
CREATE USER 'consulta_vet'@'localhost' IDENTIFIED BY 'ConsultaVet2026!';
GRANT SELECT ON veterinaria_integrador.v_ficha_mascota       TO 'consulta_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.v_historial_clinico   TO 'consulta_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.v_vacunas_pendientes  TO 'consulta_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.v_resumen_veterinario TO 'consulta_vet'@'localhost';
GRANT SELECT ON veterinaria_integrador.v_internaciones_activas TO 'consulta_vet'@'localhost';

FLUSH PRIVILEGES;


-- ============================================================================
-- 6. DML - TRANSACCIONES, COMMIT, ROLLBACK Y FUNCIONES NATIVAS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 6.1 INSERT en 2 tablas relacionadas dentro de una transaccion
-- ----------------------------------------------------------------------------
START TRANSACTION;

INSERT INTO propietario (nombre, apellido, dni, telefono, email, direccion)
VALUES ('Sofia', 'Herrera', '33111222', '2615550106', 'sofia.herrera@mail.com', 'Rivadavia 456');

SET @id_duenio_nuevo = LAST_INSERT_ID();

INSERT INTO mascota (nombre, fecha_nacimiento, sexo, antecedentes_clinicos, id_propietario, id_raza)
VALUES ('Chispita', '2024-02-01', 'Hembra', 'Sin antecedentes.', @id_duenio_nuevo, 4);

COMMIT;

-- ----------------------------------------------------------------------------
-- 6.2 UPDATE multitabla con funciones nativas
-- ----------------------------------------------------------------------------
START TRANSACTION;

UPDATE consulta c
INNER JOIN diagnostico d ON d.id_consulta = c.id_consulta
INNER JOIN tratamiento t ON t.id_consulta = c.id_consulta
SET c.motivo          = CONCAT(c.motivo, ' (reprogramada)'),
    d.descripcion     = UPPER(d.descripcion),
    t.duracion_dias   = t.duracion_dias + 7
WHERE c.id_consulta = 7;

COMMIT;

-- ----------------------------------------------------------------------------
-- 6.3 DELETE con transaccion y borrado en cascada
--     Al eliminar la consulta 9 se eliminan su diagnostico y su tratamiento
--     por las claves foraneas ON DELETE CASCADE.
-- ----------------------------------------------------------------------------
START TRANSACTION;

DELETE FROM consulta WHERE id_consulta = 9;

COMMIT;

-- ----------------------------------------------------------------------------
-- 6.4 ROLLBACK: la insercion se deshace y la tabla queda igual
-- ----------------------------------------------------------------------------
START TRANSACTION;

INSERT INTO propietario (nombre, apellido, dni, telefono, email, direccion)
VALUES ('Prueba', 'Rollback', '99000111', '0000000000', 'rollback@mail.com', 'Calle Falsa 123');

SELECT COUNT(*) AS propietarios_dentro_de_la_transaccion FROM propietario;

ROLLBACK;

SELECT COUNT(*) AS propietarios_despues_del_rollback FROM propietario;

-- ----------------------------------------------------------------------------
-- 6.5 UPDATE con funciones nativas sobre una tabla
-- ----------------------------------------------------------------------------
START TRANSACTION;

UPDATE propietario
SET telefono = CONCAT('+54 9 ', telefono),
    email    = LOWER(email)
WHERE id_propietario = 3;

COMMIT;


-- ============================================================================
-- 7. CONSULTAS DE VERIFICACION
-- ============================================================================

-- 7.1 JOIN de 4 tablas: historial de una mascota
SELECT
    m.nombre                    AS mascota,
    c.fecha,
    c.motivo,
    d.descripcion               AS diagnostico,
    CONCAT(v.nombre, ' ', v.apellido) AS veterinario
FROM mascota m
INNER JOIN consulta c     ON c.id_mascota = m.id_mascota
INNER JOIN veterinario v  ON v.id_veterinario = c.id_veterinario
LEFT JOIN diagnostico d   ON d.id_consulta = c.id_consulta
WHERE m.nombre = 'Firulais'
ORDER BY c.fecha;

-- 7.2 GROUP BY + HAVING: veterinarios con 2 o mas consultas
SELECT
    CONCAT(v.nombre, ' ', v.apellido) AS veterinario,
    v.especialidad,
    COUNT(c.id_consulta)              AS total_consultas
FROM veterinario v
LEFT JOIN consulta c ON c.id_veterinario = v.id_veterinario
GROUP BY v.id_veterinario, v.nombre, v.apellido, v.especialidad
HAVING COUNT(c.id_consulta) >= 2
ORDER BY total_consultas DESC;

-- 7.3 LIKE con comodines: busqueda por nombre de mascota o apellido del duenio
SELECT
    m.nombre                          AS mascota,
    CONCAT(p.nombre, ' ', p.apellido) AS duenio,
    p.telefono
FROM mascota m
INNER JOIN propietario p ON p.id_propietario = m.id_propietario
WHERE m.nombre LIKE '%a%'
   OR p.apellido LIKE 'G%'
ORDER BY p.apellido, m.nombre;

-- 7.4 Subconsulta: mascotas sin ninguna consulta
SELECT
    m.nombre AS mascota,
    CONCAT(p.nombre, ' ', p.apellido) AS duenio
FROM mascota m
INNER JOIN propietario p ON p.id_propietario = m.id_propietario
WHERE NOT EXISTS (
    SELECT 1
    FROM consulta c
    WHERE c.id_mascota = m.id_mascota
)
ORDER BY m.nombre;

-- 7.5 Subconsulta + agregacion: veterinario con mas consultas
SELECT
    CONCAT(v.nombre, ' ', v.apellido) AS veterinario,
    COUNT(c.id_consulta)              AS total_consultas
FROM veterinario v
INNER JOIN consulta c ON c.id_veterinario = v.id_veterinario
GROUP BY v.id_veterinario, v.nombre, v.apellido
HAVING COUNT(c.id_consulta) = (
    SELECT MAX(total)
    FROM (
        SELECT COUNT(*) AS total
        FROM consulta
        GROUP BY id_veterinario
    ) AS conteo
);

-- 7.6 Funcion de ventana: ranking de veterinarios por consultas
SELECT
    veterinario,
    total_consultas,
    RANK() OVER (ORDER BY total_consultas DESC) AS ranking
FROM (
    SELECT
        CONCAT(v.nombre, ' ', v.apellido) AS veterinario,
        COUNT(c.id_consulta)              AS total_consultas
    FROM veterinario v
    LEFT JOIN consulta c ON c.id_veterinario = v.id_veterinario
    GROUP BY v.id_veterinario, v.nombre, v.apellido
) AS resumen
ORDER BY ranking;

-- 7.7 Consulta sobre las vistas
SELECT * FROM v_ficha_mascota ORDER BY mascota;
SELECT * FROM v_vacunas_pendientes;
SELECT * FROM v_internaciones_activas;
SELECT * FROM v_resumen_veterinario ORDER BY total_consultas DESC;


-- ============================================================================
-- 8. VERIFICACION FINAL
-- ============================================================================

SELECT 'especie' AS tabla, COUNT(*) AS filas FROM especie
UNION ALL SELECT 'raza',         COUNT(*) FROM raza
UNION ALL SELECT 'propietario',  COUNT(*) FROM propietario
UNION ALL SELECT 'mascota',      COUNT(*) FROM mascota
UNION ALL SELECT 'veterinario',  COUNT(*) FROM veterinario
UNION ALL SELECT 'consulta',     COUNT(*) FROM consulta
UNION ALL SELECT 'diagnostico',  COUNT(*) FROM diagnostico
UNION ALL SELECT 'tratamiento',  COUNT(*) FROM tratamiento
UNION ALL SELECT 'vacunacion',   COUNT(*) FROM vacunacion
UNION ALL SELECT 'cirugia',      COUNT(*) FROM cirugia
UNION ALL SELECT 'internacion',  COUNT(*) FROM internacion;

-- Fin del script.
