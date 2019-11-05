SELECT  grantee,table_name,privilege,owner FROM dba_tab_privs
  WHERE table_name IN ('DBMS_DEBUG_JDWP'
                      ,'DBMS_LDAP'
                      ,'httpuritype'
                      ,'UTL_INADDR'
                      ,'UTL_HTTP'
                      ,'UTL_MAIL'
                      ,'UTL_SMTP'
                      ,'UTL_TCP'
                      ,'WWV_FLOW_WEBSERVICES_API' );


create user osama identified by osama ;
create user rob identified by rob;
grant connect to osama	;
grant connect to rob;


BEGIN
  DBMS_NETWORK_ACL_ADMIN.append_host_ace (
    host       => 'osamaoracle.com', 
    ace        => xs$ace_type(privilege_list => xs$name_list('http'),
                              principal_name => 'osama',
                              principal_type => xs_acl.ptype_db)); 
END;/


BEGIN
  DBMS_NETWORK_ACL_ADMIN.append_host_ace (
    host       => 'osamaoracle.com', 
    ace        => xs$ace_type(privilege_list => xs$name_list('http'),
                              principal_name => 'osama',
                              principal_type => xs_acl.ptype_db)); 
END;/




SELECT acl, principal, privilege, is_grant FROM dba_network_acl_privileges;

SELECT acl, principal, privilege, is_grant FROM dba_network_acl_privileges;

SELECT HOST,grant_type,principal,principal_type,privilege    FROM dba_host_aces;

BEGIN
  DBMS_NETWORK_ACL_ADMIN.append_host_ace (
    host       => 'osamaoracle.com', 
    ace        => xs$ace_type(privilege_list => xs$name_list('http'),
                              principal_name => 'rob',
                              principal_type => xs_acl.ptype_db)); 
END;/



SELECT HOST,grant_type,principal,principal_type,privilege    FROM dba_host_aces;

BEGIN
  DBMS_NETWORK_ACL_ADMIN.remove_host_ace (
    host             => 'osamaoracle.com', 
    ace              => xs$ace_type(privilege_list => xs$name_list('http'),
                                    principal_name => 'ROB',
                                    principal_type => xs_acl.ptype_db),
    remove_empty_acl => TRUE); 
END;/


SELECT HOST, ACL, ACLID, ACL_OWNER FROM dba_host_acls;
SELECT HOST, ACL, ACLID, ACL_OWNER FROM dba_host_acls;

SELECT HOST,grant_type,principal,principal_type,privilege FROM dba_host_aces;


BEGIN
  DBMS_NETWORK_ACL_ADMIN.remove_host_ace (     
  
    host             => 'osamaoracle.com', 
    ace              => xs$ace_type(privilege_list => xs$name_list('http'),
                                    principal_name => 'OSAMA',
                                    principal_type => xs_acl.ptype_db),
    remove_empty_acl => TRUE); 
END;/


SELECT HOST, ACL, ACLID, ACL_OWNER FROM dba_host_acls;



  SELECT HOST,lower_port,upper_port,acl,DECODE (
            DBMS_NETWORK_ACL_ADMIN.check_privilege_aclid (aclid,'OSAMA', 'http'),
            1, 'GRANTED',
            0, 'DENIED',
            'DENIED')
            PRIVILEGE
    FROM dba_network_acls WHERE HOST IN (SELECT *
               FROM TABLE (
                       DBMS_NETWORK_ACL_UTILITY.domains ('osamaoracle.com')))
ORDER BY DBMS_NETWORK_ACL_UTILITY.domain_level (HOST) DESC,
         lower_port,
         upper_port;


SELECT HOST,lower_port,upper_port,acl,DECODE (
            DBMS_NETWORK_ACL_ADMIN.check_privilege_aclid (aclid,'ROB', 'http'),
            1, 'GRANTED',
            0, 'DENIED',
            'DENIED')
            PRIVILEGE
    FROM dba_network_acls WHERE HOST IN (SELECT *
               FROM TABLE (
                       DBMS_NETWORK_ACL_UTILITY.domains ('osamaoracle.com')))
ORDER BY DBMS_NETWORK_ACL_UTILITY.domain_level (HOST) DESC,
         lower_port,
         upper_port;


GRANT EXECUTE ON UTL_HTTP TO OSAMA, ROB;
Conn Osama/Osama@orcl;

DECLARE
  req_host   UTL_HTTP.REQ;
  resp_host  UTL_HTTP.RESP;
BEGIN
  req_host:= UTL_HTTP.BEGIN_REQUEST('http://osamaoracle.com');
  resp_host  := UTL_HTTP.GET_RESPONSE(req_host);
  UTL_HTTP.END_RESPONSE(resp_host);
END; /



Conn Osama/Osama@orcl;

-- you will get ORA-29273: HTTP request failed
DECLARE
  req_host   UTL_HTTP.REQ;
  resp_host  UTL_HTTP.RESP;
BEGIN
  req_host:= UTL_HTTP.BEGIN_REQUEST('http://osamaoracle.com');
  resp_host  := UTL_HTTP.GET_RESPONSE(req_host);
  UTL_HTTP.END_RESPONSE(resp_host);
END; /



BEGIN
DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE (
host => 'smtp.localdomain.net',
lower_port => null,
upper_port => null,
ace => xs$ace_type(privilege_list => xs$name_list('smtp'),
principal_name => 'OSAMA',
principal_type => XS_ACL.PTYPE_DB));
END;/




select principal,host,lower_port,upper_port,privilege from dba_host_aces 

Conn sys/sys@orcl
@$ORACLE_HOME/rdbms/admin/utlsmtp.sql
@$ORACLE_HOME/rdbms/admin/prvtmail.plb
GRANT EXECUTE ON utl_smtp TO OSAMA;
 ALTER SYSTEM SET smtp_out_server=' smtp.localdomain.net' SCOPE=both;
 
 
 Conn Osama/Osama@orcl;

BEGIN
  send_mail_test(p_to        => 'mymail@company.com',
            p_from      => 'admin@company.com',
            p_message   => 'This is ACL message.',
            p_smtp_host => 'smtp.ourcompany.net');
END;/

SELECT ANY_PATH FROM RESOURCE_VIEW
WHERE ANY_PATH LIKE '/sys/acls/%.xml';

SELECT acl,principal,privilege,is_grant,
       TO_CHAR(start_date, 'DD-MON-YYYY') AS start_date,
       TO_CHAR(end_date, 'DD-MON-YYYY') AS end_date
FROM   dba_network_acl_privileges;


BEGIN
  dbms_network_acl_admin.drop_acl(all_owner_acl.xml ');
END;/


orapki wallet add -wallet $ORACLE_HOME/wallet -trusted_cert -cert "/home/oracle/certs/certifcate.cer" -pwd oracle123

EXEC UTL_HTTP.set_wallet('file: /u01/app/oracle/product/12.2.0/dbhome_1/wallet', 'oracle123');
EXEC test_url('https://osamaoracle.com/', 'username', 'password');


