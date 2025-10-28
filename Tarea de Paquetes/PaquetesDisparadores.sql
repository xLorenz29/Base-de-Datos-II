-- Creación del Paquete PKG_EMPLOYEE
CREATE OR REPLACE PACKAGE pkg_employee AS

  -- CRUD
  PROCEDURE insertar_empleado(
    p_employee_id   employees.employee_id%TYPE,
    p_first_name    employees.first_name%TYPE,
    p_last_name     employees.last_name%TYPE,
    p_email         employees.email%TYPE,
    p_job_id        employees.job_id%TYPE,
    p_salary        employees.salary%TYPE,
    p_hire_date     employees.hire_date%TYPE,
    p_department_id employees.department_id%TYPE
  );

  PROCEDURE actualizar_empleado(
    p_employee_id employees.employee_id%TYPE,
    p_salary      employees.salary%TYPE
  );

  PROCEDURE eliminar_empleado(
    p_employee_id employees.employee_id%TYPE
  );

  FUNCTION obtener_empleado(
    p_employee_id employees.employee_id%TYPE
  ) RETURN employees%ROWTYPE;

  -- 3.1.1
  PROCEDURE empleados_mas_rotacion;

  -- 3.1.2
  FUNCTION promedio_contrataciones_mensual RETURN NUMBER;

  -- 3.1.3
  PROCEDURE gastos_por_region;

  -- 3.1.4
  FUNCTION tiempo_servicio RETURN NUMBER;

  -- 3.1.5
  FUNCTION horas_laboradas_mes(
    p_employee_id NUMBER,
    p_mes NUMBER,
    p_anio NUMBER
  ) RETURN NUMBER;

  -- 3.1.6
  FUNCTION horas_faltadas_mes(
    p_employee_id NUMBER,
    p_mes NUMBER,
    p_anio NUMBER
  ) RETURN NUMBER;

  -- 3.1.7
  PROCEDURE reporte_sueldo_mensual(
    p_mes NUMBER,
    p_anio NUMBER
  );

END pkg_employee;
/

--Cuerpo del Paquete
CREATE OR REPLACE PACKAGE BODY pkg_employee AS

  PROCEDURE insertar_empleado(...) IS
  BEGIN
    INSERT INTO employees
    VALUES (...);
  END;

  PROCEDURE actualizar_empleado(...) IS
  BEGIN
    UPDATE employees
    SET salary = p_salary
    WHERE employee_id = p_employee_id;
  END;

  PROCEDURE eliminar_empleado(...) IS
  BEGIN
    DELETE FROM employees
    WHERE employee_id = p_employee_id;
  END;

  FUNCTION obtener_empleado(...) RETURN employees%ROWTYPE IS
    v_emp employees%ROWTYPE;
  BEGIN
    SELECT * INTO v_emp
    FROM employees
    WHERE employee_id = p_employee_id;
    RETURN v_emp;
  END;

--Emplearon que más rotaron de puesto
  PROCEDURE empleados_mas_rotacion IS
  BEGIN
    FOR r IN (
      SELECT e.employee_id,
             e.last_name,
             e.first_name,
             e.job_id,
             j.job_title,
             COUNT(jh.job_id) AS cambios
      FROM employees e
      JOIN job_history jh ON e.employee_id = jh.employee_id
      JOIN jobs j ON e.job_id = j.job_id
      GROUP BY e.employee_id, e.last_name, e.first_name, e.job_id, j.job_title
      ORDER BY cambios DESC
      FETCH FIRST 4 ROWS ONLY
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(
        r.employee_id || ' ' || r.last_name || ' ' || r.first_name ||
        ' | Puesto: ' || r.job_title ||
        ' | Cambios: ' || r.cambios
      );
    END LOOP;
  END;

--Promedio de contrataciones mensuales
  FUNCTION promedio_contrataciones_mensual RETURN NUMBER IS
    v_promedio NUMBER;
  BEGIN
    SELECT AVG(mensual) INTO v_promedio
    FROM (
      SELECT COUNT(*) AS mensual
      FROM employees
      GROUP BY EXTRACT(MONTH FROM hire_date), EXTRACT(YEAR FROM hire_date)
    );
    RETURN v_promedio;
  END;

--Gastos por región
  PROCEDURE gastos_por_region IS
  BEGIN
    FOR r IN (
      SELECT r.region_name,
             SUM(e.salary) total_salarios,
             COUNT(e.employee_id) cantidad_empleados,
             MIN(e.hire_date) empleado_mas_antiguo
      FROM employees e
      JOIN departments d ON e.department_id = d.department_id
      JOIN locations l ON d.location_id = l.location_id
      JOIN countries c ON l.country_id = c.country_id
      JOIN regions r ON c.region_id = r.region_id
      GROUP BY r.region_name
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(
        r.region_name || ' | Total: ' || r.total_salarios ||
        ' | Empleados: ' || r.cantidad_empleados ||
        ' | Más antiguo: ' || r.empleado_mas_antiguo
      );
    END LOOP;
  END;

--Tiempo de servicio y vacaciones
  FUNCTION tiempo_servicio RETURN NUMBER IS
    v_total NUMBER := 0;
  BEGIN
    FOR r IN (SELECT hire_date FROM employees) LOOP
      v_total := v_total + MONTHS_BETWEEN(SYSDATE, r.hire_date);
    END LOOP;
    RETURN v_total;
  END;

--Tabla de horario y asistencia
CREATE TABLE Horario (
  dia_semana VARCHAR2(10),
  turno VARCHAR2(10),
  hora_inicio DATE,
  hora_fin DATE
);

CREATE TABLE Empleado_Horario (
  dia_semana VARCHAR2(10),
  turno VARCHAR2(10),
  employee_id NUMBER
);

CREATE TABLE Asistencia_Empleado (
  employee_id NUMBER,
  dia_semana VARCHAR2(10),
  fecha_real DATE,
  hora_inicio_real DATE,
  hora_fin_real DATE
);

--Horas laboradas en un mes
  FUNCTION horas_laboradas_mes(
    p_employee_id NUMBER,
    p_mes NUMBER,
    p_anio NUMBER
  ) RETURN NUMBER IS
    v_horas NUMBER := 0;
  BEGIN
    FOR r IN (
      SELECT ae.hora_inicio_real, ae.hora_fin_real
      FROM Asistencia_Empleado ae
      WHERE ae.employee_id = p_employee_id
        AND EXTRACT(MONTH FROM ae.fecha_real) = p_mes
        AND EXTRACT(YEAR FROM ae.fecha_real) = p_anio
    ) LOOP
      v_horas := v_horas + (r.hora_fin_real - r.hora_inicio_real) * 24;
    END LOOP;
    RETURN v_horas;
  END;

--Trigger para validar asistencia
CREATE OR REPLACE TRIGGER trg_validar_asistencia
BEFORE INSERT ON Asistencia_Empleado
FOR EACH ROW
BEGIN
  IF TO_CHAR(:NEW.fecha_real,'DAY') != :NEW.dia_semana THEN
    RAISE_APPLICATION_ERROR(-20001,'Día no coincide');
  END IF;
END;
/

--Validar salario por puesto
CREATE OR REPLACE TRIGGER trg_validar_salario
BEFORE INSERT OR UPDATE OF salary ON employees
FOR EACH ROW
DECLARE
  v_min jobs.min_salary%TYPE;
  v_max jobs.max_salary%TYPE;
BEGIN
  SELECT min_salary, max_salary
  INTO v_min, v_max
  FROM jobs
  WHERE job_id = :NEW.job_id;

  IF :NEW.salary NOT BETWEEN v_min AND v_max THEN
    RAISE_APPLICATION_ERROR(-20002,'Salario fuera de rango');
  END IF;
END;
/  