create user test_data1 no authentication
quota unlimited on enc_dat
default tablespace enc_dat;
-- now give test_data1 some permissions, so we can create the objects
-- we are going to need for this demo.
grant create session, create procedure, create table to test_data1;

conn rlockard[test_data1]@orclpdb1
create table test_data1.t1 as select * from sys.all_objects;
create table test_data1.t2 as select * from sys.all_indexes;
-- check to make sure we have some data to play with.
select count(*) from test_data1.t1;
select count(*) from test_data1.t2;
create or replace package test_data1.p_test 
authid definer -- this is redundant, by default the package 
                -- will be created with definers rights.
as
    procedure p_count_object_types(p_obj_type in varchar2,
                                   p_kount out integer);
end p_test;
/
create or replace package body test_data1.p_test as
procedure p_count_object_types(p_obj_type in varchar2,
                               p_kount out integer) is
    begin
        select count(*)
        into p_kount
        from test_data1.t1 -- note, I always use the schema name to remove ambiguity 
        where object_type = p_obj_type;
        -- This is nasty! Does the business logic really want the code
        -- to drop a table?
        execute immediate 'drop table t2';
    end p_count_object_types;
end p_test;
/

grant execute on test_data1.p_test to test_user1;

conn test_user1@orclpdb1
select count(*) from test_data1.t1;  -- you’ll get an ORA-00942 error
select count(*) from test_data1.t2;  -- you’ll get an ORA-00942 error

set serveroutput on;
declare
x integer; -- just a dumb variable to hold the object count.
begin
  test_data1.p_test.p_count_object_types(p_obj_type => 'VIEW', 
                                         p_kount => x);
  sys.dbms_output.put_line('the count of object types is ' || to_char(x));
end;
/

conn rlockard[test_data1]/DontTellAnyoneMyPassword@orclpdb1
select count(*) from test_data1.t2;

create or replace package test_data1.p_test 
authid current_user -- yea’ it can be confusing, I’ve been using the word invokers
                    -- rights; however the syntax is current_user.
as

    procedure p_count_object_types(p_obj_type in varchar2,
                                   p_kount out integer);
end p_test;
/

create or replace package body test_data1.p_test as
procedure p_count_object_types(p_obj_type in varchar2,
                               p_kount out integer) is
    begin
        select count(*)
        into p_kount
        from test_data1.t1 -- note, I always use the schema name to remove ambiguity 
        where object_type = p_obj_type;
        -- note we commented out the following line, we actually want this code to
        -- work, to do that we’ll need to grant select on test_data1.t1 to the 
        -- user executing the code.
        -- execute immediate 'drop table t2';
    end p_count_object_types;
end p_test;
/

conn rlockard@orclpdb1
create role test_role;
grant select on test_data1.t1 to test_role;
grant test_role to test_user1;

exit
sql test_user1@orclpdb1

select count(*) from test_data1.t1;  -- this will work
select count(*) from test_data1.t2;  -- you’ll get an ORA-00942 error, you don’t 
                                          -- have permission to see test_data1.t2.

set serveroutput on;
declare
x integer; -- just a dumb variable to hold the object count.
begin
  test_data1.p_test.p_count_object_types(p_obj_type => 'VIEW', 
                                         p_kount => x);
  sys.dbms_output.put_line('the count of object types is ' || to_char(x));
end;
/

create or replace package hr_api.test_12_1_pkg
  accessible by (hr_bl.hr_adm_pkg, hr_bl.hr_usr_lookups)
as
  procedure p_upd_emp_phone (p_emp_id    in  integer,
                               p_emp_phone in  varchar2,
                               p_err_code  out integer);
  procedure p_sel_emp_phone(p_emp_id in integer,
                              p_emp_phone out varchar2,
                              p_err_code  out integer)
end test_12_1_pkg;
/

create or replace package hr_api.test_12_2_pkg as
  procedure p_upd_emp_phone (p_emp_id    in  integer,
                             p_emp_phone in  varchar2,
                             p_err_code  out integer)
  accessible by (package hr_bl.hr_adm_pkg);
  procedure p_sel_emp_phone(p_emp_id in integer,
                              p_emp_phone out varchar2,
                              p_err_code  out integer)
  accessible by (package hr_bl.hr_adm_pkg,
                 package hr_bl.hr_usr_lookups);
end test_12_2_pkg;
/
-- we’re just creating the package body to demonstrate accessible by. This
-- package body has no functionality. 
create or replace package body hr_api.test_12_2_pkg as
  procedure p_upd_emp_phone (p_emp_id    in  integer,
                             p_emp_phone in  varchar2,
                             p_err_code  out integer) 
  accessible by (package hr_bl.hr_adm_pkg)
  is
  begin
    sys.dbms_output.put_line('DO SOMETHING');
  end p_upd_emp_phone;

  procedure p_sel_emp_phone(p_emp_id in integer,
                            p_emp_phone out varchar2,
                            p_err_code  out integer) 
  accessible by (package hr_bl.hr_adm_pkg,
               package hr_bl.hr_usr_lookups)
  is
  begin
    sys.dbms_output.put_line('DO SOMETHING ELSE');
  end p_sel_emp_phone;
end test_12_2_pkg;
/

conn rlockard@orclpdb1
select granted_role from user_role_privs;

sql >declare
  x integer; -- just a dumb variable to catch p_err_code. we expect
             -- p_err_code to be null, because this code will be blocked.
  s_phone hr.employees.phone_number%type;
begin
  hr_api.test_12_2_pkg.p_sel_emp_phone(p_emp_id    => 1,
                                       p_emp_phone => s_phone,
                                       p_err_code  => x);
end;
/

conn rlockard@orclpdb1
create user hr_api no authentication;

create user hr_api;

alter user hr grant connect through rlockard;

conn <proxy user>[<schema only account>]@<database service> 

conn rlockard[hr]@orclpdb1

$ sql rlockard@orclpdb1
alter user hr no authentication;

alter user hr default tablespace enc_dat;
alter user hr quota unlimited on enc_dat;
alter user hr quota unlimited on enc_idx;

select segment_name, segment_type
from sys.dba_segments
where owner = 'HR';

-- move a table, do this for all the tables in the HR schema
alter table hr.employees move tablespace enc_dat;
-- move an index, do this for all the indexes in the HR schema.
alter index hr.emp_email_uk rebuild tablespace enc_idx;

create user hr_api no authentication;
-- now we need to grant the privileges required for the HR_API schema.
grant create session, create procedure to hr_api;


create user hr_decls no authentication;
grant create session, create procedure to hr_decls;

create user hr_bl no authentication;
grant create session, create procedure to hr_bl;
alter user hr grant connect through rlockard;
alter user hr_api grant connect through rlockard;
alter user hr_decls grant connect through rlockard;
alter user hr_bl grant connect through rlockard;

grant select on hr.employees to hr_api;
grant select on hr.employees to hr_decls;
grant select on hr.departments to hr_api;
grant select on hr.departments to hr_decls;
grant select on hr.locations to hr_api;
grant select on hr.locations to hr_decls;

grant update on hr.departments to hr_api;
grant insert on hr.departments to hr_api;
grant delete on hr.departments to hr_api;
grant update on hr.locations to hr_api;
grant insert on hr.locations to hr_api;
grant delete on hr.locations to hr_api;

conn rlockard[hr_decls]@orclpdb1

sqlplus rlockard[hr_decls]@orclpdb1 

sql rlockard[hr_decls]@orclpdb1 

create or replace package hr_decls.decl IS
       -- define the cursors
  CURSOR emp_cur IS
  SELECT employee_id,
         first_name,
         last_name,
         email,
         phone_number,
         hire_date,
         job_id,
         salary,
         commission_pct,
         manager_id,
         department_id,
         ssn
  FROM hr.employees;

  -- types definitions
  subtype st_emp IS emp_cur%rowtype;
  type t_emps is table of st_emp index by pls_integer;
end decl;
/

grant execute on hr_decls.decl to hr_api;
grant execute on hr_decls.decl to hr_bl;

conn rlockard@orclpdb1
Set Up Roles and Privileges 

create role hr_emp_sel_rol;
create role hr_dept_sel_rol;
create role hr_loc_sel_rol;
-- create the insert roles
create role hr_emp_ins_rol;
create role hr_dept_ins_rol;
create role hr_loc_ins_rol;
--we'll create the update role. 
create role hr_emp_upd_rol;
create role hr_dept_upd_rol;
create role hr_loc_upd_rol;
-- create the delete roles
create role hr_emp_del_rol;
create role hr_dept_del_rol;
create role hr_loc_del_rol;

grant select on hr.employees to hr_emp_sel_rol;
grant select on hr.departments to hr_dept_sel_rol;
grant select on hr.locations to hr_loc_sel_rol;
grant insert on hr.employees to hr_emp_ins_rol;
grant insert on hr.departments to hr_dept_ins_rol;
grant insert on hr.locations to hr_loc_ins_rol;
grant update on hr.employees to hr_emp_upd_rol;
grant update on hr.departments to hr_dept_upd_rol;
grant update on hr.locations to hr_loc_upd_rol;
grant delete on hr.employees to hr_emp_del_rol;
grant delete on hr.departments to hr_dept_del_rol;
grant delete on hr.locations to hr_loc_del_rol;

grant hr_emp_sel_rol to hr_api with delegate option;
grant hr_dept_sel_rol to hr_api with delegate option;
grant hr_loc_sel_rol to hr_api with delegate option;
grant hr_emp_upd_rol to hr_api with delegate option;
grant hr_dept_upd_rol to hr_api with delegate option;
grant hr_loc_upd_rol to hr_api with delegate option;
grant hr_emp_ins_rol to hr_api with delegate option;
grant hr_dept_ins_rol to hr_api with delegate option;
grant hr_loc_ins_rol to hr_api with delegate option;
grant hr_emp_del_rol to hr_api with delegate option;
grant hr_dept_del_rol to hr_api with delegate option;
grant hr_loc_del_rol to hr_api with delegate option;

conn rlockard[hr_api]@orclpdb1

create or replace package hr_api.emp_sel_pkg
authid current_user
as
  function f_get_emp(p_first_name in varchar2 default null,
                     p_last_name  in varchar2 default null,
                     p_emp_id     in integer  default null) 
  return hr_decls.decl.t_emps
  accessible by package (hr_bl.manage_emp_pkg);
end emp_sel_pkg;
/


grant hr_emp_sel_rol to package hr_api.emp_sel_pkg;

create or replace package body hr_api.emp_sel_pkg as
  -- rlockard 20190215 initial version.
  -- this package function will take an employee name
create or replace package body hr_api.emp_sel_pkg as
  -- rlockard 20190215 initial version.
  -- this package function will take an employee name
  function f_get_emp(p_first_name in varchar2 default null,
                     p_last_name  in varchar2 default null,
                     p_emp_id     in integer  default null)
  return hr_decls.decl.t_emps 
  accessible by package (hr_bl.manage_emp_pkg)
  is
  
  tt_emps hr_decls.decl.t_emps;
  i_error_id integer; -- if an error is generated, this is the primary key
                      -- in the help.errors table. 
                      -- use the help_api.get_errors_pkg.f_get_error with 
                      -- the error id to get a json clob of the error stack.
  begin
    -- check to make sure we have something to lookup. we're not allowing
    -- a generic lookup of all the data; nope, allowing someone to 
    -- extract all of the data is a bad idea. We can tighten this up more
    -- by using Virtual Private Databases (VPD). We'll add in VPD at the 
    -- end to really make this tight. 
    if p_first_name is null and p_last_name is null and p_emp_id is null then
        return tt_emps; -- tt_emps will be empty.
    end if;
    -- now lets find the employee and return a table of employees to the calling
    -- package. As you can see, we are making some of the sensitive columns null,
    -- this way we can reuse the hr_decls.decl.t_emps type for the package that 
    -- hr administrators can use. We can also use redaction. We’ll modify this in
    -- another chapter to include redaction.
    begin
      select employee_id,
           first_name,
           last_name,
           email,
           phone_number,
           hire_date,
           job_id,
           null,                       --salary
           null,                       --commission_pct
           manager_id,
           department_id,
           null                        --ssn
      bulk collect into tt_emps
      from hr.employees
      where (first_name = p_first_name and p_first_name is not null)
        and (last_name  = p_last_name and  p_last_name is not null)
        and (employee_id = p_emp_id and p_emp_id is not null);
      return tt_emps;
    exception when others then
      -- We don’t have the errorstack package built yet, so comment out the
      -- line until we get that built.
      -- help_api.errorstack_pkg.main(p_error_id => i_error_id);
      -- <debugging code>
      sys.dbms_output.put_line('there was an error: ' || to_char(i_error_id) ||
                               '  '|| sqlerrm);
      <debugging code>
      return tt_emps;  -- tt_emps will be empty.
    end;
  end f_get_emp;
end emp_sel_pkg;
/


create or replace package hr_bl.manage_emp_pkg
authid current_user as
  procedure p_ins_emp(p_emp in hr_decls.decl.t_emps);
end manage_emp_pkg;
/

create or replace package body  hr_bl.manage_emp_pkg as
-- build a package that
--      a) add an employee. Assigns the employee
--              to a department and location.
--  b) gets employee information by name,
--              department or location.
--      c) determine if the person getting the
--              employee information can get ssn
--              based on ip address (subnet), roles
--              assigned (select_emp_sensitive_role)
--              and authentication method.

  procedure p_ins_emp(p_emp in hr_decls.decl.t_emps) as
  i_id   integer;                                -- the primary key that will
                                                  -- be returned by the insert proc.
  begin
    -- for demo purposes, usr1 builds an employee
    -- record and calls pinsemp.
    -- insert a row into the employees record.
    -- do all the business logic then do the insert.
    hr_api.emp_insert_pkg.p_ins_emp(p_emp => p_emp, p_id => i_id);
    -- print the employee id.
    sys.dbms_output.put_line('employee id = ' || to_char(i_id));
  end p_ins_emp;
end manage_emp_pkg;
/

Grant execute on the package to exec_hr_emp_code_role.
grant execute on hr_bl.manage_emp_pkg to exec_hr_emp_code_role;

sql rlockard@orclpdb1
create user help no authentication
default tablespace enc_dat
quota unlimited on enc_dat;
alter user help quota unlimited on enc_idx;
-- grant create session and create table.
grant create session to help;
grant create table to help;
-- create the help_api schema and grant create session and create procedure.
create user help_api no authentication;
grant create session to help_api;
grant create procedure to help_api;

alter user help grant connect through rlockard;
alter user help_api grant connect through rlockard;

conn rlockard[help]@orclpdb1
-- we need two sequences one for errors and the other for error_lines.
create sequence help.error_lines_seq;
create sequence help.errors_seq;
-- Now, let’s create the errors table. This will be the parent table of errors.
-- after an error stack is created, the primary key returned will be to the 
-- errors table.
create table help.errors
 (    id number,
      username varchar2(128 char),
      ip_address varchar2(15 char),
      timestamp# timestamp,
      edition varchar2(128 char)
 ) 
tablespace enc_dat ;

-- perform the alter table commands. Create the PK unique index, and make not null
-- columns not null.
create unique index help.errors_pk on help.errors (id) tablespace enc_idx ;
alter table help.errors modify (id not null enable);
alter table help.errors modify (username not null enable);
-- create the primary key constraint.
alter table help.errors add constraint errors_pk primary key (id) 
using index tablespace enc_idx  enable;

-- for some reason, comments on columns have fallen out of favor. Yes, it’s more 
-- typing; however, when someone else needs to go back six months or a year from 
-- now and need to figure out what a column is used for, then comments really do help
-- a lot. We always try to name columns in a way they make sense; however, just
-- because a column name makes sense to you, does not mean it will make sense to
-- someone else. On another note, if you have a status column that takes codes, please
-- put in the comment what the codes are, what they mean, or if your using a lookups
-- table, add into the comment the name of the lookups table you’ll be using. Thank
-- you from everyone who has to maintain your database after you leave for a better
-- job.
comment on column help.errors.id is 'primary key for the errors table.';
comment on column help.errors.username is 'the user that executed the code.';
comment on column help.errors.ip_address is 'the ip address that the code was executed from.';
comment on column help.errors.timestamp# is 'the timestamp when the code was executed.';

create table help.error_lines
(   id            number,
    errors_id     number,
    dynamic_depth number,
    owner         varchar2(128 char),
    subprg_name   varchar2(128 char),
    error_msg     varchar2(256 char),
    error_number  number,
    plsql_line    number,
    lex_depth     number
)
tablespace enc_dat;

-- create an index on the foreign key column to the errors table.
create index help.error_lines_idx on help.error_lines (errors_id)
tablespace enc_idx;
-- create an index for the primary key.
create unique index help.error_lines_pk on help.error_lines (id)
tablespace enc_idx;
-- make not null columns, not null
alter table help.error_lines modify (id not null enable);
alter table help.error_lines modify (errors_id not null enable);
alter table help.error_lines modify (dynamic_dept not null enable);
-- enable the primary key constraint.
alter table help.error_lines add constraint error_lines_pk primary key (id)
using index tablespace enc_idx  enable;


comment on column help.error_lines.owner is 'the owner of the pl/sql unit that was called.';
comment on column help.error_lines.subprg_name is 'the function,procedure that was called in a package. we are leaving this nullable for now. there is the possibility that a procedure,function,trigger can be called and will not be part of a package.';

grant select, insert on help.errors to help_api;
grant select, insert on help.error_lines to help_api;
grant select on help.errors_seq to help_api;
grant select on help.error_lines_seq to help_api;

conn rlockard[help_api]@orclpdb1
-- create the package. we're going to make this authid current_user
-- to support CBAC (Code Based Access Control)
create or replace package  help_api.errorstack_pkg 
authid current_user
as
    procedure main(p_error_id    out integer);
end errorstack_pkg;
/

create or replace package body  help_api.errorstack_pkg as

    -- this procedure will get the stack values for each call in the stack.
    -- we are not exposing this to the specification because it will only
    -- be used internal to this package. because of this, we are forward
    -- defining it.
    procedure p_call_stack_main(p_error_id in integer) is

        i_depth               integer;        -- the error stack depth
        i_line_id             integer;        -- the error_line pk.
        i_error_number        integer;        -- The Error number
        s_error_msg           varchar2(256);  -- The Error Message
        s_sub_program         varchar2(128);  -- sub program name
    begin
        for i_depth in reverse 1 .. sys.utl_call_stack.dynamic_depth()
        loop
            -- the assignments in this block don’t seem to play well in the
            -- insert statement. So, we moved them into a block. In my copious
            -- free time, figure out why they don’t play well in an insert statement. 
            begin
              s_sub_program  := sys.utl_call_stack.concatenate_subprogram(
                                          utl_call_stack.subprogram(i_depth));
              i_error_number := sys.utl_call_stack.error_number(i_depth);
              s_error_msg    := sys.utl_call_stack.error_msg(i_depth);
              -- this exception is to be expected when there are no errors
.             -- in the stack.
            exception when others then
              i_error_number := 0;
              s_error_msg := null;
            end;

            -- get the next sequence number.
            select help.error_lines_seq.nextval
            into i_line_id
            from dual;
            -- insert the line into help.error_lines.
            insert into help.error_lines values (
                    i_line_id,       -- primary key
                    p_error_id,      -- fk to help.errors.
                    i_depth,         -- dynamic_depth
                    sys.utl_call_stack.owner(i_depth), -- pl/sql unit owner
                    s_sub_program,   -- pl/sql unit and sub program 1st value.
                    s_error_msg,     -- error message
                    i_error_number,  -- error number
                    sys.utl_call_stack.unit_line(i_depth),     -- pl/sql line number
                    sys.utl_call_stack.lexical_depth(i_depth)  -- lexical depth
                    );
        end loop;
        commit;
    end p_call_stack_main;

    -- the main calling procedure for the error stack package.
    procedure main (p_error_id out integer)is
    pragma autonomous_transaction;
    --i_error_id    integer;        -- help.errors pk.
    begin
        -- get the next sequence for errors.
        select help.errors_seq.nextval
        into p_error_id
        from dual;
        -- create the base error in help.errors table.
        insert into help.errors values (p_error_id, -- help.errors pk
                            sys_context('userenv', 'session_user'),
                            sys_context('userenv', 'ip_address'),
                            current_timestamp,
                            sys_context('userenv','current_edition_name')
                            );
        -- populate the error_lines table using p_call_stack_main.
        p_call_stack_main(p_error_id => p_error_id);
        -- commit the transaction sense this is an autonomous transaction
        -- we are not worried about the commit having side effects.
        commit;
        -- return the error id. this is done through the out 
        -- parameter p_error_id. so there is not going to be a 
        -- formal return statement.
    end main;
end errorstack_pkg;
/

conn rlockard@orclpdb1
create role help_desk_insert_rol; 
grant insert on help.errors to help_desk_insert_rol;
grant insert on help.error_lines to help_desk_insert_rol;
grant select on help.errors_seq to help_desk_insert_rol;
grant select on help.error_lines_seq to help_desk_insert_rol;

-- the next role will be used to extract data from the errors table.
create role help_desk_select_rol;
grant select on help.errors to help_desk_select_rol;
grant select on help.error_lines to help_desk_select_rol;

grant help_desk_insert_rol to help_api with delegate option;
grant help_desk_select_rol to help_api with delegate option;

$ sql rlockard[help_api]@orclpdb1
grant help_desk_insert_rol to package errorstack_pkg;

grant execute on help_api.errorstack_pkg to public;


conn test_user1@orclpdb1

set serveroutput on
create procedure test_user1.x as
 x          integer; -- just a dumb variable
 i_error_id integer; -- to capture the error primary key.
begin
  -- this statement will generate two errors, 1) trying to put a string into an
  -- integer and 2) too many rows, trying to put many values into one variable.
  select username
  into x
  from all_users;
exception when others then
  help_api.errorstack_pkg.main(i_error_id);
  -- let the user know we have an error. The user will get the primary key to the
  -- help.errors table that can be used to find out what the error stack is. Again,
  -- the beauty of this is the error id will change for each error. An attacker has
  -- no way to learn anything about what the error is to fine tune their attack.
  sys.dbms_output.put_line('oh crap, we got an error :-( ' || to_char(i_error_id));
end;
/

conn rlockard@orclpdb1
-- 
-- start with the package specification. The json document will be
-- returned in a clob (character large object)
create or replace package help_api.get_errors_pkg 
authid current_user
as
  function f_get_error(p_error_id in number) return clob;
end get_errors_pkg;
/

create or replace package body help_api.get_errors_pkg as
  function f_get_error(p_error_id in number) return clob is
  json_clob     clob;
  cursor error_cur is
    select json_object('id'            value e.id, 
                       'username'      value e.username,
                       'ip_address'    value e.ip_address,
                       'timestamp'     value e.timestamp#,
                       'edition'       value e.edition,
                       'errors_id'     value l.errors_id,
                       'dynamic_depth' value l.dynamic_depth,
                       'owner'         value l.owner,
                       'subprg_name'   value l.subprg_name,
                       'error_msg'     value l.error_msg,
                       'error_number'  value l.error_number,
                       'plsql_line'    value l.plsql_line,
                       'lex_depth'     value l.lex_depth) err
    from help.errors e,
         help.error_lines l
    where e.id = l.errors_id
      and e.id = p_error_id;
  begin
    for error_rec in error_cur
    loop
      json_clob := json_clob || error_rec.err;
    end loop;
    return json_clob;
  end f_get_error;
end get_errors_pkg;
/

conn rlockard[help_api]@orclpdb1
grant help_desk_select_rol to package get_errors_pkg;
-- now we want to narrow down who can get the errors data.
-- for this we are going to create a help desk role that will
-- have execute privileges on the errors_pkg.
-- connect as the dba account to create the help desk role.
conn rlockard@orclpdb1
create role help_desk_rol;
--now we'll grant the help desk role to a help desk user.
create user help_user1 identified by DontTellAnyoneMyPassword;
grant create session, help_desk_rol to help_user1;
grant execute on help_api.get_errors_pkg to help_desk_rol;