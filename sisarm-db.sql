-- ==============================================================================
-- 1. ESTRUCTURA DE LA BASE DE DATOS ARANCELARIA (SISARM)
-- ==============================================================================
CREATE DATABASE IF NOT EXISTS SISARM;
USE SISARM;

-- TABLA: secciones (Jerarquía Nivel 1)
CREATE TABLE IF NOT EXISTS secciones (
    id_seccion INT PRIMARY KEY,
    nombre_seccion VARCHAR(255) NOT NULL,
    notas_seccion TEXT
);

-- TABLA: capitulos (Jerarquía Nivel 2 - 2 dígitos)
CREATE TABLE IF NOT EXISTS capitulos (
    id_capitulo VARCHAR(5) PRIMARY KEY, -- Ej: '01'
    id_seccion INT NOT NULL,
    nombre_capitulo VARCHAR(255) NOT NULL,
    notas_capitulo TEXT,
    nota_complementaria_nandina TEXT,
    FOREIGN KEY (id_seccion) REFERENCES secciones(id_seccion)
);

-- TABLA: partidas (Jerarquía Nivel 3 - 4 dígitos)
CREATE TABLE IF NOT EXISTS partidas (
    codigo_partida VARCHAR(10) PRIMARY KEY, -- Ej: '01.01'
    id_capitulo VARCHAR(5) NOT NULL,
    descripcion_mercancia TEXT NOT NULL,
    FOREIGN KEY (id_capitulo) REFERENCES capitulos(id_capitulo)
);

-- TABLA: subpartidas (Jerarquía Nivel 4 - 10 dígitos - Clasificable)
CREATE TABLE IF NOT EXISTS subpartidas (
    codigo_subpartida VARCHAR(15) PRIMARY KEY, -- Ej: '0101.21.00.00'
    codigo_partida VARCHAR(10) NOT NULL,
    descripcion_subpartida TEXT NOT NULL,
    FOREIGN KEY (codigo_partida) REFERENCES partidas(codigo_partida)
);

-- TABLA: despacho_aduanero (Tributos y Documentos No Arancelarios)
CREATE TABLE IF NOT EXISTS despacho_aduanero (
    id_despacho INT AUTO_INCREMENT PRIMARY KEY,
    codigo_subpartida VARCHAR(15) NOT NULL,
    ga_porcentaje DECIMAL(5,2), -- Gravamen Arancelario (GA%)
    porcentaje_iehd DECIMAL(5,2), -- Impuesto a los Consumos Específicos (ICE/IEHD%)
    unidad_medida VARCHAR(10),    -- Unidad de Medida (Ej: U, kg, m2)
    medida_en_frontera VARCHAR(50), -- Medida de Control (Ej: 100%, 0%)
    tipo_documento VARCHAR(20),   -- Tipo de Documento (Ej: 'C': Certificado, 'L': Licencia)
    tipo_entidad_emite VARCHAR(100), -- Entidad de control (Ej: SENASAG, IBTE)
    disp_legal VARCHAR(100),     -- Disposición Legal (Ej: Ley 830 - D.S. 515)
    documento VARCHAR(100),       -- Nombre del Documento
    observaciones TEXT,
    FOREIGN KEY (codigo_subpartida) REFERENCES subpartidas(codigo_subpartida)
);

-- TABLA: preferencias_arancelarias (Acuerdos comerciales)
CREATE TABLE IF NOT EXISTS preferencias_arancelarias (
    id_preferencia INT AUTO_INCREMENT PRIMARY KEY,
    codigo_subpartida VARCHAR(15) NOT NULL,
    tipo_preferencia VARCHAR(100), -- Ej: ALADI, MERCOSUR
    valor_preferencia DECIMAL(5,2), -- GA preferencial (Ej: 0.00)
    condiciones TEXT,
    FOREIGN KEY (codigo_subpartida) REFERENCES subpartidas(codigo_subpartida)
);

-- NUEVA TABLA: log_auditoria (Para trazabilidad e inmutabilidad - HISTORIA 4)
CREATE TABLE IF NOT EXISTS log_auditoria (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    fecha_hora_accion DATETIME NOT NULL, -- Sello de tiempo inmutable
    id_usuario VARCHAR(50) NOT NULL,
    nombre_usuario VARCHAR(100),
    tipo_evento ENUM('CONSULTA_DB', 'EXPORTACION_DATOS', 'MODIFICACION_DATOS') NOT NULL,
    detalle_accion TEXT NOT NULL, -- Describe la acción y, si aplica, los parámetros (ej. filtros)
    ip_origen VARCHAR(45), -- Opcional, para mayor trazabilidad
    -- Índice para búsquedas por fecha/tipo de evento
    INDEX idx_fecha_tipo (fecha_hora_accion, tipo_evento) 
);
-- ==============================================================================
-- 2. INSERCIÓN DE DATOS ARANCELARIOS (JERARQUÍA Y SUBPARTIDAS)
-- ==============================================================================

-- SECCIONES
INSERT INTO secciones (id_seccion, nombre_seccion, notas_seccion) VALUES
(1, 'ANIMALES VIVOS Y PRODUCTOS DEL REINO ANIMAL', '1. En esta Sección, cualquier referencia a un género o a una especie determinada de un animal se aplica también, salvo disposición en contrario, a los animales jóvenes de ese género o de esa especie.\n2. Salvo disposición en contrario, cualquier referencia en la Nomenclatura a productos secos o desecados alcanza también a los productos deshidratados, evaporados o liofilizados.')
ON DUPLICATE KEY UPDATE nombre_seccion=VALUES(nombre_seccion);

-- CAPÍTULOS
INSERT INTO capitulos (id_capitulo, id_seccion, nombre_capitulo, notas_capitulo, nota_complementaria_nandina) VALUES
('01', 1, 'ANIMALES VIVOS', '1. Este Capítulo comprende todos los animales vivos, excepto:\na) los peces, los crustáceos, moluscos y demás invertebrados acuáticos, de las partidas 03.01, 03.06, 03.07 o 03.08;\nb) los cultivos de microorganismos y demás productos de la partida 30.02;\nc) los animales de la partida 95.08.', '1. En los Capítulos 1 y 3, las expresiones Reproductores de raza pura, para reproducción o cría industrial, para lidia y para carrera, comprenden los animales considerados como tales por las autoridades competentes de los Países Miembros.'),
('02', 1, 'CARNE Y DESPOJOS COMESTIBLES', '1. Este Capítulo no comprende:\na) respecto de las partidas 02.01 a 02.08 y 02.10, los productos impropios para la alimentación humana;\nb) los insectos comestibles, sin vida (partida 04.10);\nc) las tripas, vejigas y estómagos de animales (partida 05.04), ni la sangre animal (partidas 05.11 o 30.02);\nd) las grasas animales, excepto los productos de la partida 02.09 (Capítulo 15).', NULL),
('03', 1, 'PESCADOS Y CRUSTÁCEOS, MOLUSCOS Y DEMÁS INVERTEBRADOS ACUÁTICOS', '1. Este Capítulo no comprende:\na) los mamíferos de la partida 01.06;\nb) la carne de los mamíferos de la partida 01.06 (partidas 02.08 o 02.10);\nc) el pescado (incluidos los hígados, huevas y lechas) ni los crustáceos, moluscos o demás invertebrados acuáticos, muertos e impropios para la alimentación humana por su naturaleza o por su estado de presentación (Capítulo 5); la harina, polvo y «pellets» de pescado o de crustáceos, moluscos o demás invertebrados acuáticos, impropios para la alimentación humana (partida 23.01); o\nd) el caviar y los sucedáneos del caviar preparados con huevas de pescado (partida 16.04).\n2. En este Capítulo, el término «pellets» designa los productos en forma de cilindro, bolita, etc., aglomerados por simple presión o con adición de una pequeña cantidad de aglutinante.\n3. Las partidas 03.05 a 03.08 no comprenden la harina, polvo y «pellets», aptos para la alimentación humana (partida 03.09).', '1. En los Capítulos 1 y 3, las expresiones Reproductores de raza pura, para reproducción o cría industrial, para lidia y para carrera, comprenden los animales considerados como tales por las autoridades competentes de los Países Miembros.')
ON DUPLICATE KEY UPDATE nombre_capitulo=VALUES(nombre_capitulo);

-- PARTIDAS
INSERT INTO partidas (codigo_partida, id_capitulo, descripcion_mercancia) VALUES
('01.01', '01', 'Caballos, asnos, mulos y burdeganos, vivos.'), ('01.02', '01', 'Bóvidos, vivos.'), ('01.03', '01', 'Cerdos, vivos.'), ('01.04', '01', 'Ovinos y caprinos, vivos.'), ('01.05', '01', 'Gallos, gallinas, patos, gansos, pavos (gallipavos) y pintadas, de las especies domésticas, vivos.'), ('01.06', '01', 'Los demás animales vivos.'),
('02.03', '02', 'Carne de porcino, fresca, refrigerada o congelada.'), ('02.04', '02', 'Carne de animales de las especies ovina o caprina, fresca, refrigerada o congelada.'), ('02.06', '02', 'Despojos comestibles de animales de las especies bovina, porcina, ovina, caprina, caballar, asnal, mular o burdegana, frescos, refrigerados o congelados.'), ('02.07', '02', 'Carne y despojos comestibles, de aves de la partida 01.05, frescos, refrigerados o congelados.'), ('02.08', '02', 'Las demás carnes y despojos comestibles, frescos, refrigerados o congelados.'), ('02.09', '02', 'Tocino sin partes magras, grasa de cerdo y grasa de ave sin fundir ni extraer de otro modo, frescos, refrigerados, congelados, salados o en salmuera, secos o ahumados.'), ('02.10', '02', 'Carne y despojos comestibles, salados, en salmuera, secos o ahumados; harinas y polvos, comestibles, de carne o de despojos.'),
('03.01', '03', 'Peces vivos.'), ('03.02', '03', 'Pescado fresco o refrigerado, excepto los filetes y demás carne de pescado de la partida 03.04.'), ('03.03', '03', 'Pescado congelado, excepto los filetes y demás carne de pescado de la partida 03.04.'), ('03.08', '03', 'Invertebrados acuáticos, excepto los crustáceos y moluscos; vivos, frescos, refrigerados, congelados, secos, salados o en salmuera; ahumados; harinas, polvos y "pellets" de invertebrados acuáticos, excepto los crustáceos, aptos para la alimentación humana.'), ('03.09', '03', 'Harina, polvo y "pellets" de pescado, incluso aptos para la alimentación humana; productos del reino animal, comestibles, no expresados ni comprendidos en otra parte del Capítulo 3.')
ON DUPLICATE KEY UPDATE descripcion_mercancia=VALUES(descripcion_mercancia);

-- SUBPARTIDAS (Detalladas - 10 dígitos)
INSERT INTO subpartidas (codigo_subpartida, codigo_partida, descripcion_subpartida) VALUES
('0101.21.00.00', '01.01', '--Reproductores de raza pura'), ('0101.29.00.00', '01.01', '--Los demás'), ('0101.30.00.00', '01.01', '-Asnos'), ('0101.90.00.00', '01.01', '-Los demás'),
('0102.21.00.00', '01.02', '--Reproductores de raza pura'), ('0102.29.10.00', '01.02', '---Para lidia'), ('0102.29.90.00', '01.02', '---Los demás'), ('0102.31.00.00', '01.02', '--Reproductores de raza pura'), ('0102.39.00.00', '01.02', '--Los demás'), ('0102.90.00.00', '01.02', '-Los demás'),
('0103.10.00.00', '01.03', '-Reproductores de raza pura'), ('0103.91.00.00', '01.03', '--De peso inferior a 50 kg'), ('0103.92.00.00', '01.03', '--De peso igual o superior a 50 kg'),
('0104.10.00.00', '01.04', '-Ovinos'), ('0104.20.00.00', '01.04', '-Caprinos'),
('0105.11.00.00', '01.05', '--Gallos y gallinas, de peso inferior o igual a 185 g'), ('0105.12.00.00', '01.05', '--Pavos (gallipavos) de peso inferior o igual a 185 g'), ('0105.13.00.00', '01.05', '--Patos de peso inferior o igual a 185 g'), ('0105.14.00.00', '01.05', '--Gansos de peso inferior o igual a 185 g'), ('0105.15.00.00', '01.05', '--Pintadas de peso inferior o igual a 185 g'), ('0105.94.00.00', '01.05', '--Gallos y gallinas, de peso superior a 185 g'), ('0105.99.00.00', '01.05', '--Los demás'),
('0106.11.00.00', '01.06', '--Primates'), ('0106.12.00.00', '01.06', '--Ballenas, delfines y marsopas...'), ('0106.13.11.10', '01.06', '----Llamas (Lama lama)'), ('0106.13.11.20', '01.06', '----Guanacos (Lama guanicoe)'), ('0106.13.12.00', '01.06', '----Alpacas (Lama pacos)'), ('0106.13.19.00', '01.06', '----Los demás'), ('0106.13.90.00', '01.06', '--Los demás camellos y demás camélidos (Camelidae)'), ('0106.14.00.00', '01.06', '--Conejos y liebres'), ('0106.19.00.10', '01.06', '---Peces'), ('0106.19.00.90', '01.06', '---Los demás'), ('0106.20.00.00', '01.06', '-Reptiles (incluidas las serpientes y tortugas de mar)'), ('0106.31.00.00', '01.06', '--Aves de rapiña'), ('0106.32.00.00', '01.06', '--Psitaciformes...'), ('0106.33.00.00', '01.06', '--Avestruces; emúes...'), ('0106.39.00.00', '01.06', '--Las demás'), ('0106.41.00.00', '01.06', '--Abejas'), ('0106.49.00.00', '01.06', '--Los demás'), ('0106.90.00.00', '01.06', '-Los demás'),
('0203.11.00.00', '02.03', '--En canales o medias canales (Fresca/Refrigerada)'), ('0203.12.00.00', '02.03', '--Piernas, paletas y sus trozos sin deshuesar (Fresca/Refrigerada)'), ('0203.19.10.00', '02.03', '---Carne deshuesada (Fresca/Refrigerada)'), ('0203.19.20.00', '02.03', '---Chuletas, costillas (Fresca/Refrigerada)'), ('0203.19.30.00', '02.03', '---Tocino con partes magras (Fresca/Refrigerada)'), ('0203.19.90.00', '02.03', '---Las demás (Fresca/Refrigerada)'), ('0203.21.00.00', '02.03', '--En canales o medias canales (Congelada)'), ('0203.22.00.00', '02.03', '--Piernas, paletas y sus trozos sin deshuesar (Congelada)'), ('0203.29.10.00', '02.03', '---Carne deshuesada (Congelada)'), ('0203.29.20.00', '02.03', '---Chuletas, costillas (Congelada)'), ('0203.29.30.00', '02.03', '---Tocino con partes magras (Congelada)'), ('0203.29.90.00', '02.03', '---Las demás (Congelada)'),
('0204.10.00.00', '02.04', '-Canales o medias canales de cordero frescas o refrigeradas'), ('0204.21.00.00', '02.04', '--En canales o medias canales (Ovinos/fresca/refrigerada)'), ('0204.22.00.00', '02.04', '--Los demás cortes sin deshuesar (Ovinos/fresca/refrigerada)'), ('0204.23.00.00', '02.04', '--Deshuesadas (Ovinos/fresca/refrigerada)'), ('0204.30.00.00', '02.04', '-Canales o medias canales de cordero congeladas'), ('0204.41.00.00', '02.04', '--En canales o medias canales (Ovinos/congelada)'), ('0204.42.00.00', '02.04', '--Los demás cortes sin deshuesar (Ovinos/congelada)'), ('0204.43.00.00', '02.04', '--Deshuesadas (Ovinos/congelada)'), ('0204.50.00.00', '02.04', '-Carne de animales de la especie caprina'),
('0206.10.00.00', '02.06', '-De la especie bovina, frescos o refrigerados'), ('0206.21.00.00', '02.06', '--Hígados (Bovino, congelados)'), ('0206.22.00.00', '02.06', '--Lenguas (Bovino, congelados)'), ('0206.29.00.00', '02.06', '--Los demás (Bovino, congelados)'), ('0206.30.00.00', '02.06', '-De la especie porcina, frescos o refrigerados'), ('0206.41.00.00', '02.06', '--Hígados (Porcina, congelados)'), ('0206.49.00.00', '02.06', '--Los demás (Porcina, congelados)'), ('0206.80.00.00', '02.06', '-Los demás, frescos o refrigerados'), ('0206.90.00.00', '02.06', '-Los demás, congelados'),
('0207.11.00.00', '02.07', '--Sin trocear, frescos o refrigerados (Gallos/gallinas)'), ('0207.12.00.00', '02.07', '--Sin trocear, congelados (Gallos/gallinas)'), ('0207.13.00.00', '02.07', '--Trozos y despojos, frescos o refrigerados (Gallos/gallinas)'), ('0207.14.00.00', '02.07', '--Trozos y despojos, congelados (Gallos/gallinas)'), ('0207.19.00.00', '02.07', '--Los demás (Gallos/gallinas)'), ('0207.24.00.00', '02.07', '--Sin trocear, frescos o refrigerados (Pavos)'), ('0207.25.00.00', '02.07', '--Sin trocear, congelados (Pavos)'), ('0207.26.00.00', '02.07', '--Trozos y despojos, frescos o refrigerados (Pavos)'), ('0207.27.00.00', '02.07', '--Trozos y despojos, congelados (Pavos)'), ('0207.41.00.00', '02.07', '--Sin trocear, frescos o refrigerados (Patos/Gansos)'), ('0207.42.00.00', '02.07', 'Sin trocear, congelados (Patos/Gansos)'), ('0207.43.00.00', '02.07', '--Hígados grasos, frescos o refrigerados (Patos/Gansos)'), ('0207.44.00.00', '02.07', '--Los demás, frescos o refrigerados (Patos/Gansos)'), ('0207.45.00.00', '02.07', '--Los demás, congelados (Patos/Gansos)'), ('0207.51.00.00', '02.07', '-Sin trocear, frescos o refrigerados (Pintadas)'), ('0207.52.00.00', '02.07', '-Sin trocear, congelados (Pintadas)'), ('0207.53.00.00', '02.07', '-Hígados grasos, frescos o refrigerados (Pintadas)'), ('0207.54.00.00', '02.07', '--Los demás, frescos o refrigerados (Pintadas)'), ('0207.55.00.00', '02.07', '--Los demás, congelados (Pintadas)'), ('0207.60.00.00', '02.07', '-De pintada'),
('0208.10.00.00', '02.08', '-De conejo o liebre'), ('0208.30.00.00', '02.08', '-De primates'), ('0208.40.00.00', '02.08', 'De ballenas, delfines y marsopas...'), ('0208.50.00.00', '02.08', 'De reptiles (incluidas las serpientes y tortugas de mar)'), ('0208.60.00.00', '02.08', 'De camellos y demás camelidos (Camelidae)'), ('0208.90.00.00', '02.08', '-Los demás'),
('0209.10.00.00', '02.09', '-De cerdo:'), ('0209.10.10.00', '02.09', '--Tocino sin partes magras'), ('0209.10.90.00', '02.09', '--Los demás'), ('0209.90.00.00', '02.09', '-Las demás'),
('0210.11.00.00', '02.10', '--Jamones, paletas, y sus trozos, sin deshuesar'), ('0210.12.00.00', '02.10', '-Tocino entreverado de panza (panceta) y sus trozos'), ('0210.19.00.00', '02.10', '--Las demás'), ('0210.20.00.00', '02.10', 'Carne de la especie bovina'), ('0210.91.00.00', '02.10', 'De primates'), ('0210.92.00.00', '02.10', 'De ballenas, delfines y marsopas...'), ('0210.93.00.00', '02.10', 'De reptiles (incluidas las serpientes y tortugas de mar)'), ('0210.99.10.00', '02.10', '-Harina y polvo comestibles, de carne o de despojos'), ('0210.99.90.00', '02.10', 'Los demás'),
('0301.11.00.00', '03.01', 'De agua dulce (Peces Ornamentales)'), ('0301.19.00.00', '03.01', '--Los demás (Peces Ornamentales)'), ('0301.91.10.00', '03.01', '---Para reproducción o cría industrial (Otros peces)'), ('0301.91.90.00', '03.01', '---Las demás (Otros peces)'), ('0301.92.00.00', '03.01', '--Anguilas (Anguilla spp.)'), ('0301.93.00.00', '03.01', '--Carpas (Cyprinus spp.,...)'), ('0301.94.00.00', '03.01', 'Atunes comunes o de aleta azul...'), ('0301.95.00.00', '03.01', '--Atunes del sur (Thunnus maccoyii)'), ('0301.99.11.00', '03.01', '--Tilapia'), ('0301.99.19.10', '03.01', '--Paiche (Arapaima gigas)'), ('0301.99.19.90', '03.01', '--Los demás'),
('0302.11.00.00', '03.02', 'Truchas (Salmo trutta, Oncorhynchus mykiss,...)'), ('0302.13.00.00', '03.02', '--Salmones del Pacífico...'), ('0302.14.00.00', '03.02', '--Salmones del Atlántico y del Danubio...'), ('0302.19.00.00', '03.02', '--Los demás (Salmónidos)'), ('0302.21.00.00', '03.02', '--Fletanes («halibut»)'), ('0302.22.00.00', '03.02', 'Sollas (Pleuronectes platessa)'), ('0302.23.00.00', '03.02', 'Lenguados (Solea spp.)'), ('0302.24.00.00', '03.02', 'Rodaballos (turbots») (Psetta maxima)'), ('0302.29.00.00', '03.02', '--Los demás (Peces planos)'), ('0302.31.00.00', '03.02', '--Albacoras o atunes blancos (Thunnus alalunga)'), ('0302.32.00.00', '03.02', 'Atunes de aleta amarilla (rabiles) (Thunnus albacares)'), ('0302.33.00.00', '03.02', 'Listados (bonitos de vientre rayado) (Katsuwonus pelamis)'), ('0302.34.00.00', '03.02', 'Patudos o atunes ojo grande (Thunnus obesus)'), ('0302.35.00.00', '03.02', 'Atunes comunes o de aleta azul...'), ('0302.36.00.00', '03.02', 'Atunes del sur (Thunnus maccoyii)'), ('0302.39.00.00', '03.02', '--Los demás (Atunes, listados, etc.)'), ('0302.41.00.00', '03.02', '--Arenques (Clupea harengus, Clupea pallasii)'), ('0302.42.00.00', '03.02', '--Anchoas (Engraulis spp.)'), ('0302.43.00.00', '03.02', 'Sardinas, sardinelas y espadines...'), ('0302.44.00.00', '03.02', '--Caballas (Scomber scombrus,...)'), ('0302.45.00.00', '03.02', '--Jureles (Trachurus spp.)'), ('0302.46.00.00', '03.02', 'Cobias (Rachycentron canadum)'), ('0302.47.00.00', '03.02', 'Peces espada (Xiphias gladius)'), ('0302.49.00.00', '03.02', '--Los demás (Peces del 0302.4)'), ('0302.51.00.00', '03.02', 'Bacalaos (Gadus morhua,...)'), ('0302.52.00.00', '03.02', 'Eglefinos (Melanogrammus aeglefinus)'), ('0302.53.00.00', '03.02', 'Carboneros (Pollachius virens)'), ('0302.54.00.00', '03.02', 'Merluzas (Merluccius spp., Urophycis spp.)'), ('0302.55.00.00', '03.02', 'Abadejos de Alaska (Theragra chalcogramma)'), ('0302.56.00.00', '03.02', 'Bacaladillas (Micromesistius poutassou,...)'), ('0302.59.00.00', '03.02', '-- Los demás (Peces Gadiformes)'), ('0302.71.00.00', '03.02', '--Tilapias (Oreochromis spp.)'), ('0302.72.00.00', '03.02', 'Bagres o peces gato (Pangasius spp.,...)'), ('0302.73.00.00', '03.02', 'Carpas (Cyprinus spp.,...)'), ('0302.74.00.00', '03.02', 'Anguilas (Anguilla spp.)'), ('0302.79.00.00', '03.02', '-- Los demás (Peces de agua dulce)'), ('0302.81.00.00', '03.02', '--Cazones y demás escualos'), ('0302.82.00.00', '03.02', '-Rayas (Rajidae)'), ('0302.83.00.00', '03.02', '-Austromerluzas antárticas y austromerluzas negras...'), ('0302.84.00.00', '03.02', 'Róbalos (Dicentrarchus spp.)'), ('0302.85.00.00', '03.02', '--Sargos (Doradas, Espáridos) (Sparidae)'), ('0302.89.00.10', '03.02', 'Paiche (Arapaima gigas)'), ('0302.89.00.90', '03.02', '-Los demás (Pescado no especificado)'), ('0302.91.00.00', '03.02', 'Higados, huevas y lechas'), ('0302.92.00.00', '03.02', 'Aletas de tiburón'), ('0302.99.00.10', '03.02', 'De truchas...'), ('0302.99.00.20', '03.02', 'De salmónidos, excepto de salmones del Pacifico...'), ('0302.99.00.90', '03.02', '---Los demás'),
('0303.11.00.00', '03.03', 'Salmones rojos (Oncorhynchus nerka)'), ('0303.12.00.00', '03.03', '--Los demás salmones del Pacifico...'), ('0303.13.00.00', '03.03', '-- Salmones del Atlántico y del Danubio...'), ('0303.19.00.00', '03.03', '- Los demás (Salmónidos)'), ('0303.23.00.00', '03.03', '--Tilapias (Oreochromis spp.)'), ('0303.24.00.00', '03.03', '--Bagres o peces gato (Pangasius spp.,...)'), ('0303.25.00.00', '03.03', '-Carpas (Cyprinus spp.,...)'), ('0303.26.00.00', '03.03', 'Anguilas (Anguilla spp.)'), ('0303.29.00.00', '03.03', '-- Los demás (Peces de agua dulce)'), ('0303.31.00.00', '03.03', '--Fletanes («halibut»)'), ('0303.32.00.00', '03.03', 'Sollas (Pleuronectes platessa)'), ('0303.33.00.00', '03.03', 'Lenguados (Solea spp.)'), ('0303.34.00.00', '03.03', 'Rodaballos (turbots ) (Psetta maxima)'), ('0303.39.00.00', '03.03', '-- Los demás (Peces planos)'), ('0303.41.00.00', '03.03', 'Albacoras o atunes blancos (Thunnus alalunga)'), ('0303.42.00.00', '03.03', '-- Atunes de aleta amarilla (rabiles) (Thunnus albacares)'), ('0303.43.00.00', '03.03', '--Listados (bonitos de vientre rayado) (Katsuwonus pelamis)'), ('0303.44.00.00', '03.03', 'Patudos o atunes ojo grande (Thunnus obesus)'), ('0303.45.00.00', '03.03', '--Atunes comunes o de aleta azul...'), ('0303.46.00.00', '03.03', 'Atunes del sur (Thunnus maccoyii)'), ('0303.49.00.00', '03.03', '-- Los demás (Atunes, listados, etc.)'), ('0303.51.00.00', '03.03', 'Arenques (Clupea harengus, Clupea pallasii)'), ('0303.53.00.00', '03.03', 'Sardinas, sardinelas y espadines...'), ('0303.54.00.00', '03.03', '--Caballas (Scomber scombrus,...)'), ('0303.55.00.00', '03.03', '--Jureles (Trachurus spp.)'), ('0303.56.00.00', '03.03', '--Cobias (Rachycentron canadum)'), ('0303.57.00.00', '03.03', '--Peces espada (Xiphias gladius)'), ('0303.59.00.00', '03.03', '--Los demás (Peces del 0303.5)'), ('0303.63.00.00', '03.03', 'Bacalaos (Gadus morhua,...)'), ('0303.64.00.00', '03.03', 'Eglefinos (Melanogrammus aeglefinus)'), ('0303.65.00.00', '03.03', '--Carboneros (Pollachius virens)'), ('0303.66.00.00', '03.03', '--Merluzas (Merluccius spp., Urophycis spp.)'), ('0303.67.00.00', '03.03', '--Abadejos de Alaska (Theragra chalcogramma)'), ('0303.68.00.00', '03.03', 'Bacaladillas (Micromesistius poutassou,...)'), ('0303.69.00.00', '03.03', '-- Los demás (Peces Gadiformes)'),
('0308.21.00.00', '03.08', 'Erizos de mar: Vivos, frescos o refrigerados'), ('0308.22.00.00', '03.08', 'Erizos de mar: Congelados'), ('0308.29.00.00', '03.08', 'Erizos de mar: - - Los demás'), ('0308.30.00.00', '03.08', 'Medusas (Rhopilema sp.): • Medusas'), ('0308.90.00.00', '03.08', '- Los demás'),
('0309.10.00.00', '03.09', 'Harina, polvo y "pellets" de pescado, incluso aptos para la alimentación humana'), ('0309.90.10.10', '03.09', '- - De crustáceos: - - - Congelados'), ('0309.90.10.90', '03.09', '- - De crustáceos: - - - Los demás'), ('0309.90.90.00', '03.09', '- - Los demás')
ON DUPLICATE KEY UPDATE descripcion_subpartida=VALUES(descripcion_subpartida);
-- ==============================================================================
-- 3. INSERCIÓN DE DATOS FUNCIONALES (DESPACHO Y PREFERENCIAS)
-- ==============================================================================

-- DATOS DE DESPACHO ADUANERO (GA%, UNIDAD, CONTROL)

INSERT INTO despacho_aduanero (codigo_subpartida, ga_porcentaje, porcentaje_iehd, unidad_medida, medida_en_frontera, tipo_documento, tipo_entidad_emite, disp_legal, documento, observaciones) VALUES
-- CAPÍTULO 1 (Animales Vivos)
('0101.21.00.00', 0.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', 'GA 0% para reproductores'),
('0101.29.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0101.30.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0101.90.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),

('0102.21.00.00', 0.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', 'GA 0% para reproductores'),
('0102.29.10.00', 0.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', 'Para lidia, GA 0%'),
('0102.29.90.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0102.31.00.00', 0.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', 'GA 0% para reproductores'),
('0102.39.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0102.90.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),

('0103.10.00.00', 0.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', 'GA 0% para reproductores'),
('0103.91.00.00', 10.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0103.92.00.00', 10.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),

('0104.10.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0104.20.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),

('0105.11.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', 'Polluelos de un día'),
('0105.12.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0105.13.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0105.14.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0105.15.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0105.94.00.00', 10.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0105.99.00.00', 10.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),

('0106.11.00.00', 20.00, NULL, 'U', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Especies protegidas'),
('0106.12.00.00', 20.00, NULL, 'U', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Especies protegidas'),
('0106.13.11.10', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', 'Llamas'),
('0106.13.11.20', 20.00, NULL, 'U', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Guanacos (CITES)'),
('0106.13.12.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', 'Alpacas'),
('0106.13.19.00', 20.00, NULL, 'U', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Otros camélidos (CITES)'),
('0106.13.90.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0106.14.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', NULL),
('0106.19.00.10', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', 'Peces vivos no ornamentales'),
('0106.19.00.90', 20.00, NULL, 'U', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Otros animales (CITES)'),
('0106.20.00.00', 20.00, NULL, 'U', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Reptiles'),
('0106.31.00.00', 20.00, NULL, 'U', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Aves de rapiña'),
('0106.32.00.00', 20.00, NULL, 'U', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Psitaciformes'),
('0106.33.00.00', 20.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', 'Avestruces, Emúes'),
('0106.39.00.00', 20.00, NULL, 'U', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Otras aves (CITES)'),
('0106.41.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Zoosanitario de Importación', 'Abejas'),
('0106.49.00.00', 20.00, NULL, 'U', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Insectos (CITES)'),
('0106.90.00.00', 20.00, NULL, 'U', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Otros (CITES/General)'),

-- CAPÍTULO 2 (Carne y Despojos Comestibles)
('0203.11.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne fresca/refrigerada'),
('0203.12.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0203.19.10.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0203.19.20.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0203.19.30.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0203.19.90.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0203.21.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne congelada'),
('0203.22.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0203.29.10.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0203.29.20.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0203.29.30.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0203.29.90.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),

('0204.10.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Ovinos frescos/refrigerados'),
('0204.21.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0204.22.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0204.23.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0204.30.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Ovinos congelados'),
('0204.41.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0204.42.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0204.43.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0204.50.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Caprinos'),

('0206.10.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Despojos frescos/refrigerados'),
('0206.21.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Despojos congelados (hígados)'),
('0206.22.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Despojos congelados (lenguas)'),
('0206.29.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Despojos congelados (los demás)'),
('0206.30.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Despojos porcinos frescos/refrigerados'),
('0206.41.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Despojos porcinos congelados (hígados)'),
('0206.49.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Despojos porcinos congelados (los demás)'),
('0206.80.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros despojos frescos/refrigerados'),
('0206.90.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros despojos congelados'),

('0207.11.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne de gallo/gallina fresca'),
('0207.12.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne de gallo/gallina congelada'),
('0207.13.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Trozos/despojos frescos'),
('0207.14.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Trozos/despojos congelados'),
('0207.19.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Los demás de gallo/gallina'),
('0207.24.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne de pavo fresca'),
('0207.25.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne de pavo congelada'),
('0207.26.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Trozos/despojos frescos de pavo'),
('0207.27.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Trozos/despojos congelados de pavo'),
('0207.41.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne de pato/ganso fresca'),
('0207.42.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne de pato/ganso congelada'),
('0207.43.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Hígados grasos frescos'),
('0207.44.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros frescos de pato/ganso'),
('0207.45.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros congelados de pato/ganso'),
('0207.51.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne de pintada fresca'),
('0207.52.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne de pintada congelada'),
('0207.53.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Hígados grasos de pintada'),
('0207.54.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros frescos de pintada'),
('0207.55.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros congelados de pintada'),
('0207.60.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'De pintada'),

('0208.10.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne de conejo o liebre'),
('0208.30.00.00', 20.00, NULL, 'kg', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Carne de primates'),
('0208.40.00.00', 20.00, NULL, 'kg', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Carne de mamíferos marinos'),
('0208.50.00.00', 20.00, NULL, 'kg', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Carne de reptiles'),
('0208.60.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne de camélidos'),
('0208.90.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Las demás carnes'),

('0209.10.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Tocino de cerdo'),
('0209.10.10.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0209.10.90.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0209.90.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Las demás grasas'),

('0210.11.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne salada/seca de cerdo'),
('0210.12.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0210.19.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', NULL),
('0210.20.00.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carne salada/seca de bovino'),
('0210.91.00.00', 20.00, NULL, 'kg', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Carne de primates salada'),
('0210.92.00.00', 20.00, NULL, 'kg', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Carne de mamíferos marinos salada'),
('0210.93.00.00', 20.00, NULL, 'kg', '100', 'C-CITES', 'SENASAG / MMAYA', 'Ley 830 - D.S. 3048', 'Permiso CITES de Importación', 'Carne de reptiles salada'),
('0210.99.10.00', 0.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Harina y polvo comestibles'),
('0210.99.90.00', 10.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Los demás salados/secos'),

-- CAPÍTULO 3 (Pescados y Crustáceos)
('0301.11.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Peces Ornamentales de agua dulce'),
('0301.19.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Peces Ornamentales marinos'),
('0301.91.10.00', 0.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Para reproducción o cría industrial (GA 0%)'),
('0301.91.90.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Los demás (truchas, etc.)'),
('0301.92.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Anguilas'),
('0301.93.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carpas'),
('0301.94.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Atunes'),
('0301.95.00.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Atunes del sur'),
('0301.99.11.00', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Tilapias'),
('0301.99.19.10', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Paiche'),
('0301.99.19.90', 5.00, NULL, 'U', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros peces vivos'),

('0302.11.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Truchas frescas/refrigeradas'),
('0302.13.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Salmones del Pacífico frescos/refrigerados'),
('0302.14.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Salmones del Atlántico frescos/refrigerados'),
('0302.19.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros salmónidos frescos/refrigerados'),
('0302.21.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Fletanes frescos/refrigerados'),
('0302.22.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Sollas frescas/refrigeradas'),
('0302.23.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Lenguados frescos/refrigerados'),
('0302.24.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Rodaballos frescos/refrigerados'),
('0302.29.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros peces planos frescos/refrigerados'),
('0302.31.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Albacoras frescas/refrigeradas'),
('0302.32.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Atunes de aleta amarilla frescos/refrigerados'),
('0302.33.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Listados frescos/refrigerados'),
('0302.34.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Patudos frescos/refrigerados'),
('0302.35.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Atunes comunes frescos/refrigerados'),
('0302.36.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Atunes del sur frescos/refrigerados'),
('0302.39.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Los demás atunes frescos/refrigerados'),
('0302.41.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Arenques frescos/refrigerados'),
('0302.42.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Anchoas frescas/refrigeradas'),
('0302.43.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Sardinas y sardinelas frescas/refrigeradas'),
('0302.44.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Caballas frescas/refrigeradas'),
('0302.45.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Jureles frescos/refrigerados'),
('0302.46.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Cobias frescas/refrigeradas'),
('0302.47.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Peces espada frescos/refrigerados'),
('0302.49.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros peces frescos/refrigerados'),
('0302.51.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Bacalaos frescos/refrigerados'),
('0302.52.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Eglefinos frescos/refrigerados'),
('0302.53.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carboneros frescos/refrigerados'),
('0302.54.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Merluzas frescas/refrigeradas'),
('0302.55.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Abadejos de Alaska frescos/refrigerados'),
('0302.56.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Bacaladillas frescos/refrigerados'),
('0302.59.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros peces Gadiformes frescos/refrigerados'),
('0302.71.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Tilapias frescas/refrigeradas'),
('0302.72.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Bagres o peces gato frescos/refrigerados'),
('0302.73.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carpas frescas/refrigeradas'),
('0302.74.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Anguilas frescas/refrigeradas'),
('0302.79.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros peces de agua dulce frescos/refrigerados'),
('0302.81.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Cazones y escualos frescos/refrigerados'),
('0302.82.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Rayas frescas/refrigeradas'),
('0302.83.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Austromerluzas frescas/refrigeradas'),
('0302.84.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Róbalos frescos/refrigerados'),
('0302.85.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Sargos frescos/refrigerados'),
('0302.89.00.10', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Paiche fresco/refrigerado'),
('0302.89.00.90', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros frescos/refrigerados'),
('0302.91.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Hígados, huevas y lechas frescas/refrigeradas'),
('0302.92.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Aletas de tiburón frescas/refrigeradas'),
('0302.99.00.10', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Despojos de truchas frescos/refrigerados'),
('0302.99.00.20', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Despojos de salmónidos frescos/refrigerados'),
('0302.99.00.90', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros despojos frescos/refrigerados'),

('0303.11.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Salmones rojos congelados'),
('0303.12.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Los demás salmones del Pacífico congelados'),
('0303.13.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Salmones del Atlántico y Danubio congelados'),
('0303.19.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros salmónidos congelados'),
('0303.23.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Tilapias congeladas'),
('0303.24.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Bagres o peces gato congelados'),
('0303.25.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carpas congeladas'),
('0303.26.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Anguilas congeladas'),
('0303.29.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros peces de agua dulce congelados'),
('0303.31.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Fletanes congelados'),
('0303.32.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Sollas congeladas'),
('0303.33.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Lenguados congelados'),
('0303.34.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Rodaballos congelados'),
('0303.39.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros peces planos congelados'),
('0303.41.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Albacoras congeladas'),
('0303.42.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Atunes de aleta amarilla congelados'),
('0303.43.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Listados congelados'),
('0303.44.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Patudos congelados'),
('0303.45.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Atunes comunes congelados'),
('0303.46.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Atunes del sur congelados'),
('0303.49.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Los demás atunes congelados'),
('0303.51.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Arenques congelados'),
('0303.53.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Sardinas y sardinelas congeladas'),
('0303.54.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Caballas congeladas'),
('0303.55.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Jureles congelados'),
('0303.56.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Cobias congeladas'),
('0303.57.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Peces espada congelados'),
('0303.59.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros peces congelados'),
('0303.63.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Bacalaos congelados'),
('0303.64.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Eglefinos congelados'),
('0303.65.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Carboneros congelados'),
('0303.66.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Merluzas congeladas'),
('0303.67.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Abadejos de Alaska congelados'),
('0303.68.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Bacaladillas congeladas'),
('0303.69.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros peces Gadiformes congelados'),

('0308.21.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Erizos de mar frescos/refrigerados'),
('0308.22.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Erizos de mar congelados'),
('0308.29.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros Erizos de mar'),
('0308.30.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Medusas'),
('0308.90.00.00', 5.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Otros invertebrados acuáticos'),

('0309.10.00.00', 0.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Harina de pescado (GA 0% para insumos)'),
('0309.90.10.10', 0.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Harina de crustáceos congelados'),
('0309.90.10.90', 0.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Harina de crustáceos demás'),
('0309.90.90.00', 0.00, NULL, 'kg', '100', 'C', 'SENASAG', 'Ley 830 - D.S. 515', 'Certificado Sanitario de Importación', 'Harina de los demás')

ON DUPLICATE KEY UPDATE ga_porcentaje=VALUES(ga_porcentaje), unidad_medida=VALUES(unidad_medida);


-- DATOS DE PREFERENCIAS ARANCELARIAS (Ejemplos)
INSERT INTO preferencias_arancelarias (codigo_subpartida, tipo_preferencia, valor_preferencia, condiciones) VALUES
('0101.21.00.00', 'ALADI - MERCOSUR (ACE 36)', 0.00, 'Requisitos de Origen'),
('0203.11.00.00', 'ALADI - MERCOSUR (ACE 36)', 0.00, 'Requisitos de Origen'),
('0207.14.00.00', 'ALADI - MERCOSUR (ACE 36)', 0.00, 'Requisitos de Origen'),
('0302.54.00.00', 'ALADI - MERCOSUR (ACE 36)', 0.00, 'Requisitos de Origen'),
('0309.10.00.00', 'ALADI - MERCOSUR (ACE 36)', 0.00, 'Requisitos de Origen')
ON DUPLICATE KEY UPDATE valor_preferencia=VALUES(valor_preferencia);

USE SISARM;

-- 1. CORRECCIÓN CRÍTICA DE AUDITORÍA: Renombra la columna 'fecha_hora_accion' a 'fecha_hora'
-- Esto soluciona el error: "Unknown column 'fecha_hora' in 'field list'"
ALTER TABLE log_auditoria 
CHANGE COLUMN fecha_hora_accion fecha_hora DATETIME NOT NULL;

-- 2. CORRECCIÓN CRÍTICA DE DESPACHO: Agrega la columna 'cliente_asociado'
-- Esto soluciona el error: "Unknown column 'despacho_aduanero_1.cliente_asociado' in 'field list'"
ALTER TABLE despacho_aduanero 
ADD COLUMN cliente_asociado VARCHAR(100);

-- NOTA: Estos comandos modifican la estructura de la tabla (schema) sin eliminar los datos existentes.
DESCRIBE despacho_aduanero;

ALTER TABLE despacho_aduanero ADD COLUMN cliente_asociado VARCHAR(100);

-- Asignar algunas subpartidas al cliente '12345678' (el que usas para probar)
UPDATE despacho_aduanero
SET cliente_asociado = '12345678'
WHERE codigo_subpartida IN ('0101.21.00.00', '0203.11.00.00', '0207.12.00.00');

-- Asignar otras subpartidas a un cliente diferente
UPDATE despacho_aduanero
SET cliente_asociado = '87654321'
WHERE codigo_subpartida IN ('0102.21.00.00', '0301.91.10.00');

-- Opcional: Verificar que los datos se guardaron
SELECT codigo_subpartida, cliente_asociado 
FROM despacho_aduanero 
WHERE cliente_asociado IS NOT NULL;

SELECT codigo_subpartida, cliente_asociado 
FROM despacho_aduanero 
WHERE codigo_subpartida LIKE '01%';
