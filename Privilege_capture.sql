create role sec_admin_rol;
grant capture_admin to sec_admin_rol;
grant sec_admin_rol to rob_security;

begin
 sys.dbms_privilege_capture.create_capture(
 name => 'database_full_capture1',
 description => 'initial full database priv capture',
 type => sys.dbms_privilege_capture.g_database);
end;
/

begin
 sys.dbms_privilege_capture.create_capture(
 name => 'check_robs_privs',
 type => sys.dbms_privilege_capture.g_context,
 condition => 'sys_context(''USERENV'', ''SESSION_USER'') = ''RLOCKARD''');
end;
/

begin
 sys.dbms_privilege_capture.create_capture(
 name => 'check_processor_and_cashier_roles',
 type => sys.dbms_privilege_capture.G_ROLE,
 roles => role_name_list('PROCESSOR_ROL', 'CASHIER_ROL');
end;
/

begin
 sys.dbms_privilege_capture.create_capture(
 name => 'check_beckys_use_of_processor_and_cashier',
 type => dbms_privilege_capture.g_role_and_context,
 roles => role_name_list('PROCESSOR_ROL', 'CASHIER_ROL'),
 condition => 'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') = ''BTHATCHER'''
 );
end;

begin
 sys.dbms_privilege_capture.enable_capture(
name => 'check_beckys_use_of_processor_and_cashier',
 run_name => 'capture_Beck_Thatcher_pass_1');
end;
/

Disable the capture for check_beckys_use_of_processor_and_cashier
sys.dbms_privilege_capture.disable_capture(
name => 'check_beckys_use_of_processor_and_cashier'
);
/

begin   sys.dbms_privilege_capture.generate_result('check_beckys_use_of_processor_and_cashier');
end;
/


begin
 sys.dbms_privilege_capture.drop_capture(name => '<capture name>');
end;
/

begin
 sys.dbms_privilege_capture.drop_capture('check_beckys_use_of_processor_and_cashier');
end;
/
select capture, module, username, used_role, obj_priv, object_owner, object_name
from sys.dba_used_privs
where capture = 'fees_capture';

select capture, module, os_user, used_role, sys_priv, admin_option
from sys.dba_used_sysprivs
where capture = 'fees_capture';

select capture, module, username, used_role, obj_priv, object_owner, object_name
from sys.dba_used_objprivs
where capture = 'fees_capture';

select capture, os_user, module, username, used_role, user_priv, inuser
from sys.dba_used_userprivs
where capture = 'fees_capture';

select capture, os_user, module, username, sys_priv, obj_priv, object_owner, object_name
from sys.dba_used_pubprivs
where capture = 'fees_capture';

select count(*)
from sys.dba_unused_privs
where capture = 'fees_capture'


select count(*)
from sys.dba_unused_sysprivs_path
where capture = 'fees_capture'
  and username = 'RLOCKARD';

select count(*)
from sys.dba_unused_objprivs_path
where capture = 'fees_capture';

select *
from sys.dba_unused_objprivs_path
where capture = 'fees_capture';

select *
from sys.dba_unused_userprivs_path
where capture = 'fees_capture';

alter table hr.employees add SSN varchar2(11);

drop user usr1;
-- set some things up.
create user usr1 identified by mYsECRETpASSWORD;
Create the hr_api schema only account. For more information on schema only accounts, read Chapter 6.

create user hr_api;
grant create session, create procedure to hr_api;

create role insert_emp_rol;
-- over privilege USR1. Yea’ it pains me to do this; however, 
-- I want to show the cleanup process.
grant select any table to usr1;  -- over privilege!!!!!
-- nope, this should not happen, these are bad practices, it’s only here
-- for demo purposes.
grant insert on hr.departments to usr1;
grant select on hr.departments to usr1;
-- I know I should not have to say this; but I will. Using the CONNECT role
-- is a corner case and you really should be using CREATE SESSION.
grant connect to usr1; -- over privilege!!!!!
-- That’s better, we’re going to setup the roles we need.
grant insert on hr.employees to insert_emp_rol;
-- Okay, for PL/SQL to compile, we need to make a direct grant to the schema 
-- the PL/SQL will be in. 
grant insert on hr.employees to hr_api;
grant select on hr.employees_seq to insert_emp_rol;
grant select on hr.employees_seq to hr_api;
grant select on hr.departments to hr_api;
-- Note the delegate option here. You’ll need this for Code Based Access Control.
grant insert_emp_rol to hr_api with delegate option;

create or replace package hr_api.manage_emp_pkg
authid current_user
as
    procedure p_insert_emp(p_first_name     in varchar2,
                           p_last_name      in varchar2,
                           p_email          in varchar2,
                           p_phone_number   in varchar2,
                           p_hire_date      in date,
                           p_job_id         in varchar2,
                           p_salary         in number,
                           p_commission_pct in number,
                           p_manager_id     in integer,
                           p_department_id  in integer,
                           p_ssn            in varchar2);
end manage_emp_pkg;
/


grant insert_emp_rol to package manage_emp_pkg;

create or replace package body hr_api.manage_emp_pkg as
    procedure p_insert_emp(p_first_name     in varchar2,
                           p_last_name      in varchar2,
                           p_email          in varchar2,
                           p_phone_number   in varchar2,
                           p_hire_date      in date,
                           p_job_id         in varchar2,
                           p_salary         in number,
                           p_commission_pct in number,
                           p_manager_id     in integer,
                           p_department_id  in integer,
                           p_ssn            in varchar2) is
    i_emp_id integer;
    begin
        select hr.employees_seq.nextval
        into i_emp_id
        from dual;
        --
        insert into hr.employees values (i_emp_id,
                                         p_first_name,
                                         p_last_name,
                                         p_email,
                                         p_phone_number,
                                         p_hire_date,
                                         p_job_id,
                                         p_salary,
                                         p_commission_pct,
                                         p_manager_id,
                                         p_department_id,
                                         p_ssn);
    commit;
    end p_insert_emp;
end manage_emp_pkg;
/

create or replace package hr_api.manage_dept_pkg
as
    procedure p_select_dept(p_dept_id in      integer,
                              p_dept_name   out varchar2,
                              p_manager_id  out integer,
                              p_location_id out integer);
end manage_dept_pkg;
/

create or replace package body hr_api.manage_dept_pkg
as
    procedure p_select_dept(p_dept_id in      integer,
                              p_dept_name   out varchar2,
                              p_manager_id  out integer,
                              p_location_id out integer) as
    begin
      select department_name,
               manager_id,
               location_id
      into p_dept_name,
            p_manager_id,
            p_location_id
      from hr.departments
      where department_id = p_dept_id;
    end p_select_dept;
end manage_dept_pkg;
/

begin
  sys.dbms_privilege_capture.create_capture(
            name  => 'hr_app_exercise1',
            type => sys.dbms_privilege_capture.g_database);
  sys.dbms_privilege_capture.enable_capture(name => 'hr_app_exercise1');
end;
/

sqlplus usr1@orcl

declare
  s_dept_name   hr.departments.department_name%type;
  i_manager_id  hr.departments.manager_id%type;
  i_location_id hr.departments.location_id%type;
begin

    hr_api.manage_emp_pkg.p_insert_emp(
            p_first_name       => 'Robert',
            p_last_name        => 'Lockard',
            p_email            => 'rob@rob.com',
            p_phone_number     => '+1.555.555.1212',
            p_hire_date        => trunc(sysdate),
            p_job_id           => 'AD_PRES',
            p_salary           => 900000,
            p_commission_pct   => .5,
            p_manager_id       => 100,
            p_department_id    => 270,
            p_ssn              => '111-22-2222');
    hr_api.manage_dept_pkg.p_select_dept(p_dept_id     => 270,
                                         p_dept_name   => s_dept_name,
                                         p_manager_id  => i_manager_id,
                                         p_location_id => i_location_id);
    sys.dbms_output.put_line('the department name is: ' || s_dept_name);
end;
/

begin
  sys.dbms_privilege_capture.disable_capture('hr_app_exercise1');
  sys.dbms_privilege_capture.generate_result('hr_app_exercise1');
end;
/

select count(*) from sys.dba_unused_privs
where capture = 'hr_app_exercise1';

select * from sys.dba_used_objprivs
where capture = 'hr_app_exercise1';

begin
  sys.dbms_privilege_capture.create_capture(
      name      => 'hr_app_exercise2',
      type     => sys.dbms_privilege_capture.g_context,
      condition => 'sys_context(''USERENV'', ''SESSION_USER'') = ''USR1''');
  sys.dbms_privilege_capture.enable_capture(name => 'hr_app_exercise2');
end;
/

begin
  sys.dbms_privilege_capture.disable_capture('hr_app_exercise2');
  sys.dbms_privilege_capture.generate_result('hr_app_exercise2');
end;
/

select username,
       used_role,
       obj_priv,
       object_owner,
       object_name,
       object_type,
       path
from sys.dba_used_objprivs_path
where capture = 'hr_app_exercise2'
order by used_role, obj_priv;

select *
from sys.dba_unused_sysprivs_path
where capture = 'hr_app_exercise2';

revoke select any table from usr1;
revoke connect from usr1;
grant create session to usr1;
create role hr_emp_sel_rol;
create role hr_dept_sel_rol;
grant select on hr.employees to hr_emp_sel_rol;
grant hr_emp_sel_rol to usr1;
grant hr_dept_sel_rol to usr1;

begin
  sys.dbms_privilege_capture.create_capture(
      name      => 'hr_app_exercise3',
      type     => sys.dbms_privilege_capture.g_context,
      condition => 'sys_context(''USERENV'', ''SESSION_USER'') = ''USR1''');
  sys.dbms_privilege_capture.enable_capture(name     => 'hr_app_exercise3',
                                            run_name => 'run_2');
end;
/
begin
  sys.dbms_privilege_capture.disable_capture('hr_app_exercise3');
  sys.dbms_privilege_capture.generate_result(name       => 'hr_app_exercise3',
                                             dependency => TRUE);
end;
/

select username, used_role, obj_priv, user_priv, object_owner, object_name, path
from sys.dba_used_privs
where capture = 'hr_app_exercise3';

select username,
       used_role,
       obj_priv,
       object_owner,
       object_name,
       object_type
from sys.dba_used_objprivs
where capture = 'hr_app_exercise3'
order by used_role, obj_priv;

select *
from sys.dba_used_sysprivs
where capture = 'hr_app_exercise3';

hr_app_exercise3	1	oracle	localhost java@localhostUSR1	CREATE SESSION	CREATE SESSION	0	


create role hr_dept_select;
grant select on hr.departments to hr_dept_select;
grant hr_dept_select to hr_api with delegate option;
revoke select on hr.departments from usr1;
grant hr_dept_select to usr1;

create or replace package hr_api.manage_dept_pkg
authid current_user
as
    procedure p_select_dept(p_dept_id in      integer,
                              p_dept_name   out varchar2,
                              p_manager_id  out integer,
                              p_location_id out integer);
end manage_dept_pkg;
/
grant hr_dept_select to package hr_api.manage_dept_pkg;

create or replace package body hr_api.manage_dept_pkg
as
    procedure p_select_dept(p_dept_id in      integer,
                              p_dept_name   out varchar2,
                              p_manager_id  out integer,
                              p_location_id out integer) as
    begin
      select department_name,
               manager_id,
               location_id
      into p_dept_name,
            p_manager_id,
            p_location_id
      from hr.departments
      where department_id = p_dept_id;
    end p_select_dept;
end manage_dept_pkg;
/
-- now the package will only run with the privileges we've granted to it.
begin
  sys.dbms_privilege_capture.create_capture(
      name      => 'hr_app_exercise4',
      type     => sys.dbms_privilege_capture.g_context,
      condition => 'sys_context(''USERENV'', ''SESSION_USER'') = ''USR1''');
  sys.dbms_privilege_capture.enable_capture(name => 'hr_app_exercise4');
end;
/

begin
  sys.dbms_privilege_capture.disable_capture('hr_app_exercise4');
  sys.dbms_privilege_capture.generate_result('hr_app_exercise4');
end;
/

select *
from sys.dba_unused_privs
where capture = 'hr_app_exercise4';

select *
from sys.dba_unused_objprivs
where capture = 'hr_app_exercise4';

select *
from sys.dba_unused_userprivs_path
where capture = 'hr_app_exercise4';

select *
from sys.dba_used_sysprivs
where capture = 'hr_app_exercise4';

select * from sys.dba_used_sysprivs_path
where capture = 'hr_app_exercise4';

begin
  sys.dbms_privilege_capture.drop_capture('hr_app_exercise1');
  sys.dbms_privilege_capture.drop_capture('hr_app_exercise2');
  sys.dbms_privilege_capture.drop_capture('hr_app_exercise3');
  sys.dbms_privilege_capture.drop_capture('hr_app_exercise4');
end;
/