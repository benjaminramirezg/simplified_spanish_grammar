CREATE TABLE type (id    integer unsigned not null auto_increment primary key, 
                   name  varchar(50)       not null,
                   class varchar(50)       not null,
                   stem  varchar(50),
                   CONSTRAINT UNIQUE (name));

CREATE TABLE inheritage (id  integer not null auto_increment primary key, 
                         subtype varchar(50)  not null,
                         supertype varchar(50)  not null);

CREATE TABLE feature (id  integer unsigned not null auto_increment primary key, 
                      name varchar(50)  not null,
                      declared_in varchar(50)  not null,
                      value varchar(50)  not null);

CREATE TABLE path  (id  integer unsigned not null auto_increment primary key, 
                    path varchar(300)  not null,
                    type varchar(50)  not null,
                    name varchar(50),
                    sharing varchar(50));