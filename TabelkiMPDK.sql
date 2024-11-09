DROP TABLE IF EXISTS opis_sali CASCADE;
CREATE TABLE opis_sali (
	id_opisu SERIAL PRIMARY KEY,
	opis TEXT NOT NULL);

DROP TABLE IF EXISTS klient CASCADE;
CREATE TABLE klient (
	id_klienta SERIAL PRIMARY KEY,
	imie TEXT NOT NULL,
	nazwisko TEXT ,
	e_mail TEXT UNIQUE NOT NULL,
	nr_telefonu VARCHAR(10),
	haslo TEXT NOT NULL);

DROP TABLE IF EXISTS sala CASCADE;
CREATE TABLE sala (
	id_sali SERIAL PRIMARY KEY,
	ilosc_miejsc INT NOT NULL,
	opis INT REFERENCES opis_sali(id_opisu) ON DELETE CASCADE);

DROP TABLE IF EXISTS seanse CASCADE;
CREATE TABLE seanse (
	id_seansu SERIAL PRIMARY KEY,
	tytul TEXT NOT NULL,
	format_filmu TEXT CHECK (format_filmu in ('2D', '3D', '2D VIP', '3D VIP')),
	godzina TIME NOT NULL,
	data_seans DATE NOT NULL,
	sala INT REFERENCES sala(id_sali) ON DELETE CASCADE);

DROP TABLE IF EXISTS statusy CASCADE;
CREATE TABLE statusy (
	id_status SERIAL PRIMARY KEY,
	nazwa_s TEXT NOT NULL);

DROP TABLE IF EXISTS rodzaje_biletow CASCADE;
CREATE TABLE rodzaje_biletow (
	id_rb SERIAL PRIMARY KEY,
	nazwa_b TEXT UNIQUE NOT NULL);







DROP TABLE IF EXISTS rezerwacje CASCADE;
CREATE TABLE rezerwacje (
	id_rezerw SERIAL PRIMARY KEY,
	klient INT REFERENCES klient(id_klienta) ON DELETE CASCADE,
	ilosc_biletow INT NOT NULL,
	data_rezerw DATE NOT NULL,
	status INT REFERENCES statusy(id_status) ON UPDATE CASCADE ON DELETE CASCADE,
	seanse INT NOT NULL);




DROP TABLE IF EXISTS cennik CASCADE;
CREATE TABLE cennik (
	id_ceny SERIAL PRIMARY KEY,
	cena DECIMAL(7,2) NOT NULL,
	nazwa_biletu TEXT REFERENCES rodzaje_biletow(nazwa_b) 
ON UPDATE CASCADE ON DELETE CASCADE,
	sala INT REFERENCES sala(id_sali) ON DELETE CASCADE);
DROP VIEW IF EXISTS ranking_tytulow;
        CREATE VIEW ranking_tytulow AS 
SELECT tytul, count(*) as ilosc_rezerwacji, sum(ilosc_biletow) AS ilosc_biletow 
FROM rezerwacje 
JOIN seanse ON (seanse.id_seansu = rezerwacje.seanse) 
GROUP BY tytul 
ORDER BY ilosc_biletow DESC;

        DROP VIEW IF EXISTS ranking_formatow;
        CREATE VIEW ranking_formatow AS
SELECT format_filmu, count(*) as ilosc_rezerwacji, sum(ilosc_biletow) AS ilosc_biletow 
FROM rezerwacje 
JOIN seanse ON (id_seansu = seanse) 	
GROUP BY format_filmu 
ORDER BY ilosc_biletow DESC;
        
        DROP VIEW IF EXISTS info_klient_sprzedaz;	
        CREATE VIEW info_klient_sprzedaz AS 
SELECT ilosc_rezerwacji, suma_biletow, klient AS id_klienta, e_mail 
FROM (SELECT COUNT(*) AS ilosc_rezerwacji, SUM(ilosc_biletow) AS suma_biletow, klient FROM rezerwacje GROUP BY klient) AS info 
JOIN klient ON (info.klient = klient.id_klienta);

        DROP VIEW IF EXISTS wszystkie_rezerwacje;
        CREATE VIEW wszystkie_rezerwacje AS 
SELECT id_rezerw, data_rezerw, e_mail, seanse AS id_seansu, ilosc_biletow, nazwa_s AS status 
FROM 
(SELECT id_rezerw, klient, ilosc_biletow, data_rezerw, seanse, nazwa_s FROM rezerwacje JOIN statusy ON (rezerwacje.status = id_status)) AS info 
JOIN klient ON (info.klient = klient.id_klienta);
        DROP VIEW IF EXISTS widok_ceny_biletow;
        CREATE VIEW widok_ceny_biletow AS
	SELECT id_ceny, cena, nazwa_biletu, ilosc_miejsc, opis_sali.opis 
FROM cennik 
	JOIN rodzaje_biletow ON (nazwa_biletu = nazwa_b) 
	JOIN sala ON (sala = id_sali) 
	JOIN opis_sali ON (sala.opis = opis_sali.id_opisu);

 DROP FUNCTION IF EXISTS usun_seans;
        CREATE OR REPLACE FUNCTION usun_seans(id_arg INT) RETURNS VOID AS $$
	DECLARE
		krotka RECORD;
	BEGIN
		SELECT * INTO krotka FROM seanse WHERE id_seansu = id_arg;
		IF (NOT FOUND) THEN
			RAISE EXCEPTION 'Nie ma takiego seansu';
		END IF;
		IF (FOUND) THEN
		DELETE FROM seanse WHERE id_seansu = id_arg;
		UPDATE rezerwacje
 		SET status = 2
		WHERE seanse = id_arg;
		END IF;
	 END;
$$ LANGUAGE 'plpgsql';

	DROP FUNCTION IF EXISTS dodaj_seans CASCADE;
CREATE OR REPLACE FUNCTION dodaj_seans()
RETURNS TRIGGER AS $$
		DECLARE 
			krotka RECORD;
		BEGIN
SELECT * INTO krotka FROM seanse WHERE format_filmu = NEW.format_filmu AND data_seans = NEW.data_seans;
			IF (NOT FOUND) THEN
				RETURN NEW;
			END IF;
IF ( (krotka.godzina > NEW.godzina + interval '2 hours') OR (NEW.godzina > krotka.godzina + interval '2 hours')) THEN
			RETURN NEW;
			ELSE
				RAISE EXCEPTION 'nie da sie';
			END IF;
		END;
$$ LANGUAGE 'plpgsql';
	
CREATE OR REPLACE TRIGGER dodaj_s_trigger BEFORE INSERT ON seanse
		FOR EACH ROW EXECUTE PROCEDURE dodaj_seans();

 	DROP FUNCTION IF EXISTS zmien_cene;
CREATE OR REPLACE FUNCTION zmien_cene(procent DECIMAL(5,2)) RETURNS VOID AS $$
		BEGIN
			UPDATE cennik SET cena = cena*(1 + procent/100);
		END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS capitalize_seans CASCADE;
CREATE OR REPLACE FUNCTION capitalize_seans()
RETURNS TRIGGER AS $$
	BEGIN
NEW.tytul := concat(upper(substring(NEW.tytul from 1 for 1)), lower(substring(NEW.tytul from 2)));
			RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER capitalize_seans_tr BEFORE INSERT OR UPDATE ON seanse
	FOR EACH ROW EXECUTE FUNCTION capitalize_seans();
	
INSERT INTO opis_sali(opis) VALUES ('sala 2d'),('sala 3d'),('sala 2d VIP'),('sala 3d VIP');

INSERT INTO sala(ilosc_miejsc, opis) VALUES (80, 1),(90,2),(60,3),(80,4);

INSERT INTO rodzaje_biletow(nazwa_b) VALUES ('ulgowy'), ('normalny');

INSERT INTO seanse(tytul, format_filmu, godzina, data_seans, sala) VALUES 
('Kot w butach', '2D', '13:00', '01-02-2023', 1), ('Kot w butach', '2D VIP', '15:00', '02-03-2023', 3),
('Kot w butach', '3D', '13:30', '01-02-2023', 2),('Kot w butach', '3D VIP', '13:00', '03-02-2023', 4),
('Kot w butach', '2D', '13:00', '05-02-2023', 1),('Kot w butach', '3D', '17:00', '05-02-2023', 2),
('Titans', '2D', '16:00', '01-02-2023', 1),('Titans', '2D VIP', '13:30', '01-02-2023', 3),
('Titans', '3D', '16:00', '01-02-2023', 2),('Titans', '3D VIP', '14:00', '01-02-2023', 4),
('Titans', '2D', '13:00', '02-02-2023', 1),('Titans', '3D', '10:00', '02-02-2023', 2),
('Shrek', '2D', '20:00', '01-02-2023', 1),('Shrek', '2D VIP', '18:00', '02-02-2023', 3),
('Shrek', '3D', '14:00', '02-02-2023', 2),('Shrek', '3D VIP', '17:00', '01-02-2023', 4),
('Shrek', '2D', '17:00', '02-02-2023', 1),('Shrek', '3D', '12:00', '03-02-2023', 2),
('Alicja w krainie czarow', '2D', '13:00', '03-02-2023', 1),('Alicja w krainie czarow', '2D VIP', '11:00', '03-02-2023', 3),
('Alicja w krainie czarow', '3D', '16:00', '03-02-2023', 2),('Alicja w krainie czarow', '3D VIP', '15:00', '02-02-2023', 4),
('Alicja w krainie czarow', '2D', '14:30', '07-02-2023', 1),('Alicja w krainie czarow', '3D', '14:00', '05-02-2023', 2),
('Avatar', '2D', '16:00', '03-02-2023', 1),('Avatar', '2D VIP', '15:00', '03-02-2023', 3),
('Avatar', '3D', '20:00', '03-02-2023', 2),('Avatar', '3D VIP', '18:00', '02-02-2023', 4),
('Avatar', '2D', '18:30', '07-02-2023', 1),('Avatar', '3D', '10:00', '05-02-2023', 2),
('Kosmonauci', '2D', '13:00', '04-02-2023', 1),('Kosmonauci', '2D VIP', '12:00', '04-02-2023', 3),
('Kosmonauci', '3D', '10:00', '04-02-2023', 2),('Kosmonauci', '3D VIP', '13:30', '05-02-2023', 4),
('Kosmonauci', '2D', '20:00', '04-02-2023', 1),('Kosmonauci', '3D', '15:00', '04-02-2023', 2),
('Kosmonauci', '2D', '17:30', '05-02-2023', 1),('Kosmonauci', '3D', '20:00', '05-02-2023', 2);

INSERT INTO statusy(nazwa_s) VALUES ('zaakceptowana'),('anulowana');

INSERT INTO klient(imie, nazwisko, e_mail, nr_telefonu, haslo) VALUES
('Magda', 'Potok', 'mpotok@gmail.com', 098765432, 'maxburgers1$'), 
('Dawid', 'Padalec', 'dpadal@gmail.com', 123456789, 'haslo01'),
('Paulina', 'Adamczyk', 'padam@wp.pl', NULL, 'piesek1'),
('Ewelina', 'Osoka', 'eosok@onet.pl', 897654312, 'kotek2'),
('Arek', 'Kolec', 'akol123@gmail.com', 656565643, 'kucyk5'),
('Kacper', 'Malczyk', 'kmal@olo.sro', 201345621, 'konik8'),
('Konrad', 'Ludwicki', 'klud@gmail.com', NULL, 'shiba543'),
('Daniel', 'Kowalicki', 'dkowal@onet.pl', 090822364, 'cockerspaniel8'),
('Magdalena', 'Tokarczuk', 'mtokar@o2.pl', 111111111, 'maltanczyk65'),
('Dawid', 'Tusznio', 'dtusz@gmail.com', 212123456, 'york76'),
('Eliza', 'Majeranek', 'emaj@gmail.com', 564327865, 'roslinka93'),
('Kamil', 'Tymianek', 'ktym@wp.pl', 123498765, 'miska2');


INSERT INTO cennik (cena, nazwa_biletu, sala) VALUES
(22.22, 'normalny', 1), (15.60, 'ulgowy', 1),
(27.20, 'normalny', 2), (19.80, 'ulgowy', 2),
(25.50, 'normalny', 3), (17.20, 'ulgowy', 3),
(31.33, 'normalny', 4), (23.50, 'ulgowy', 4);

INSERT INTO rezerwacje(klient, ilosc_biletow, data_rezerw, status, seanse) VALUES
(1, 2, '26-01-2023', 1, 36),(2, 2, '26-01-2023', 2, 36),(3, 7, '27-01-2023', 1, 12),
(4, 3, '27-01-2023', 1, 11),(5, 4, '27-01-2023', 1, 10),(6, 2, '28-01-2023', 1, 13),
(7, 3, '28-01-2023', 2, 11),(8, 5, '28-01-2023', 1, 5),(9, 6, '29-01-2023', 2, 5),
(10, 7, '29-01-2023', 1, 21),(11, 2, '29-01-2023', 1, 15),(12, 3, '29-01-2023', 1, 10),
(1, 1, '30-01-2023', 2, 11),(2, 4, '30-01-2023', 1, 23),(3, 4, '30-01-2023', 1, 28),
(4, 1, '31-01-2023', 1, 7),(5, 2, '31-01-2023', 2, 32),(2, 1, '31-01-2023', 1, 31);

