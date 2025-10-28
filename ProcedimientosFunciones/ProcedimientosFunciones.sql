--Ejercicios
--Color y ciudad de las partes (P) que no son de París y pesan más de 10
CREATE OR REPLACE PROCEDURE sp_4_1_1 
IS
BEGIN
  FOR r IN (
    SELECT p#, pname, color, city, weight
    FROM P
    WHERE city <> 'Paris'
      AND weight > 10
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(r.p#||' - '||r.color||' - '||r.city||' - '||r.weight);
  END LOOP;
END;

--Para todas las partes, obtenga el número de parte y el peso de dichas partes en gramos.
CREATE OR REPLACE PROCEDURE sp_4_1_2 
IS
BEGIN
  FOR r IN (
    SELECT p#, pname, weight, weight * 453.59237 AS peso_gramos FROM P
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Parte ' || r.p# || ' -> ' || r.weight || ' lbs = ' || r.peso_gramos || ' g');
  END LOOP;
END;

--Detalle completo de todos los proveedores
CREATE OR REPLACE PROCEDURE sp_4_1_3 
IS
BEGIN
  FOR r IN (SELECT * FROM S) LOOP
    DBMS_OUTPUT.PUT_LINE('Proveedor: '||r.s#||' - '||r.sname||' - Status: '||r.status||' - Ciudad: '||r.city);
  END LOOP;
END;

--Combinaciones de proveedores y partes colocalizadas
CREATE OR REPLACE PROCEDURE sp_4_1_4 
IS
BEGIN
  FOR r IN (
    SELECT s.s#, s.sname, p.p#, p.pname, s.city
    FROM S s JOIN P p ON s.city = p.city
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(r.sname||' ( '||r.s#||' )  -  '||r.pname||' ( '||r.p#||' )  -  Ciudad: '||r.city);
  END LOOP;
END;

--Pares de ciudades proveedor–parte
CREATE OR REPLACE PROCEDURE sp_4_1_5 
IS
BEGIN
  FOR r IN (
    SELECT DISTINCT s.city AS proveedor_ciudad, p.city AS parte_ciudad
    FROM S s JOIN SP sp ON s.s# = sp.s#
             JOIN P p ON sp.p# = p.p#
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(r.proveedor_ciudad||' ' ||r.parte_ciudad);
  END LOOP;
END;

--Obtenga todos los pares de proveedor tales que los dos proveedores
--del par estén co-localizados
CREATE OR REPLACE PROCEDURE sp_4_1_6 IS
BEGIN
  FOR r IN (
    SELECT s1.s# AS prov1, s2.s# AS prov2, s1.city
    FROM S s1, S s2
    WHERE s1.city = s2.city
      AND s1.s# < s2.s#
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('('||r.prov1||', '||r.prov2||') - Ciudad: '||r.city);
  END LOOP;
END;


--Número total de proveedores.
CREATE OR REPLACE FUNCTION fn_total_proveedores
RETURN NUMBER
IS
  v_total NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM S;
  RETURN v_total;
END;

--Cantidad mínima y la cantidad máxima para la parte P2
CREATE OR REPLACE FUNCTION fn_min_max_p2
RETURN VARCHAR2
IS
  v_min NUMBER;
  v_max NUMBER;
BEGIN
  SELECT MIN(qty), MAX(qty)
  INTO v_min, v_max
  FROM SP
  WHERE p# = 'P2';

  RETURN 'Parte P2 - Mínimo: ' || v_min || ', Máximo: ' || v_max;
END;

--Total despachado por parte
CREATE OR REPLACE PROCEDURE sp_4_1_9 IS
BEGIN
  FOR r IN (
    SELECT p.p#, p.pname, SUM(sp.qty) AS total
    FROM P p JOIN SP sp ON p.p# = sp.p#
    GROUP BY p.p#, p.pname
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(r.p#||' - '||r.pname||' → Total: '||r.total);
  END LOOP;
END;

--Partes abastecidas por más de un proveedor
CREATE OR REPLACE PROCEDURE sp_4_1_10 IS
BEGIN
  FOR r IN (
    SELECT p#
    FROM SP
    GROUP BY p#
    HAVING COUNT(DISTINCT s#) > 1
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Parte '||r.p#);
  END LOOP;
END;

--Proveedores que abastecen la parte P2
CREATE OR REPLACE PROCEDURE sp_4_1_11 IS
BEGIN
  FOR r IN (
    SELECT DISTINCT s.sname
    FROM S s JOIN SP sp ON s.s# = sp.s#
    WHERE sp.p# = 'P2'
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Proveedor: '||r.sname);
  END LOOP;
END;

--Proveedores que abastecen al menos una parte
CREATE OR REPLACE PROCEDURE sp_4_1_12 
IS
BEGIN
  FOR r IN (
    SELECT DISTINCT s.sname
    FROM S s JOIN SP sp ON s.s# = sp.s#
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Proveedor: '||r.sname);
  END LOOP;
END;

--Proveedores con estado menor al máximo
CREATE OR REPLACE PROCEDURE sp_4_1_13 IS
  v_max NUMBER;
BEGIN
  SELECT MAX(status) INTO v_max FROM S;

  FOR r IN (
    SELECT s#, sname, status
    FROM S
    WHERE status < v_max
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(r.s#||' - '||r.sname||' (status: '||r.status||')');
  END LOOP;
END;

--Proveedores que abastecen la parte P2 (usando EXISTS)
CREATE OR REPLACE PROCEDURE sp_4_1_14 
IS
BEGIN
  FOR r IN (
    SELECT sname
    FROM S s
    WHERE EXISTS (
      SELECT 1 FROM SP sp
      WHERE sp.s# = s.s#
        AND sp.p# = 'P2'
    )
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Proveedor: '||r.sname);
  END LOOP;
END;

--Proveedores que NO abastecen la parte P2
CREATE OR REPLACE PROCEDURE sp_4_1_15 IS
BEGIN
  FOR r IN (
    SELECT sname
    FROM S s
    WHERE NOT EXISTS (
      SELECT 1 FROM SP sp
      WHERE sp.s# = s.s#
        AND sp.p# = 'P2'
    )
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Proveedor: '||r.sname);
  END LOOP;
END;

--Proveedores que abastecen TODAS las partes
CREATE OR REPLACE PROCEDURE sp_4_1_16 IS
BEGIN
  FOR r IN (
    SELECT s.s#, s.sname
    FROM S s
    WHERE NOT EXISTS (
      SELECT 1 FROM P p
      WHERE NOT EXISTS (
        SELECT 1 FROM SP sp
        WHERE sp.s# = s.s#
          AND sp.p# = p.p#
      )
    )
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Proveedor: '||r.sname);
  END LOOP;
END;

--Partes que pesan más de 16 libras o son abastecidas por S2
CREATE OR REPLACE PROCEDURE sp_4_1_17 IS
BEGIN
  FOR r IN (
    SELECT DISTINCT p.p#, p.pname, p.weight
    FROM P p
    WHERE p.weight > 16
       OR p.p# IN (SELECT p# FROM SP WHERE s# = 'S2')
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Parte: '||r.p#||' - '||r.pname||' - '||r.weight||' lbs');
  END LOOP;
END;


