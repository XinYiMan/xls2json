unit uExtended_fphttpapp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpapp, INIFiles;

type
    TUserItem = object

      id          : string;
      username    : string;
      password    : string;
      directory   : string;
      active      : boolean;

    end;

type
    TArrayUserItem = array of TUserItem;

var
   Application_port               : integer;
   Application_with_ssl           : boolean;
   web_app_title                  : string;
   web_app_version                : string;
   web_app_author                 : string;
   Location                       : string;
   CertificatePath                : string;
   PrivateKeyPath                 : string;
   UsersList                      : TArrayUserItem;
   TokenPassword                  : string;
   TokenMinExpired                : integer;

CONST
     DIR_FILES   = 'files';
     DIR_DEFAULT = 'default';

procedure LoadConfigIni(ApplicationLocation : string; config_name : string);
function ExistsValidUser(username : string; password : string; var id : string; var directory : string) : boolean;

implementation

procedure LoadConfigIni(ApplicationLocation : string; config_name : string);
var
   INI        : TINIFile;
   usersCount : integer;
   i          : integer;
begin
     Location                      := ApplicationLocation;

     INI                           := TINIFile.Create(ApplicationLocation + config_name);

     Application_port              := StrToIntDef(INI.ReadString('Config','Port','9090'),9090);
     Application_with_ssl          := StrToBoolDef(INI.ReadString('Config','ActiveSSL','FALSE'),FALSE);
     web_app_title                 := INI.ReadString('Config','web_app_title','Your app name');
     web_app_version               := INI.ReadString('Config','web_app_version','Your version');
     web_app_author                := INI.ReadString('Config','web_app_author','Your name');
     CertificatePath               := INI.ReadString('Config','CertificatePath','certificate.crt');
     PrivateKeyPath                := INI.ReadString('Config','PrivateKeyPath','privateKey.key');
     TokenPassword                 := INI.ReadString('Config','TokenPassword','Password123');
     TokenMinExpired               := StrToIntDef(INI.ReadString('Config','TokenMinExpired','20'),20);
     usersCount                    := StrToIntDef(INI.ReadString('Config','Users','0'),0);

     for i:= 0 to usersCount - 1 do
     begin
          SetLength(UsersList, Length(UsersList)+1);
          UsersList[Length(UsersList)-1].id          := INI.ReadString('Users','ID_' + IntToStr(i) ,'');
          UsersList[Length(UsersList)-1].username    := INI.ReadString('Users','USERNAME_' + IntToStr(i),'');
          UsersList[Length(UsersList)-1].password    := INI.ReadString('Users','PASSWORD_' + IntToStr(i),'');
          UsersList[Length(UsersList)-1].directory   := INI.ReadString('Users','DIR_' + IntToStr(i),'');
          UsersList[Length(UsersList)-1].active      := StrToBoolDef(INI.ReadString('Users','ACTIVE_' + IntToStr(i),'FALSE'),FALSE);
     end;


     if Application_with_ssl then
     begin

          if not FileExists(CertificatePath) then
          begin
               Application_with_ssl := false;
          end;

          if not FileExists(PrivateKeyPath) then
          begin
               Application_with_ssl := false;
          end;

     end;

     Ini.Free;
end;

function ExistsValidUser(username: string; password: string; var id: string;
  var directory: string): boolean;
var
   ret : boolean;
   i   : integer;
begin

     ret := false;
     i   := 0;

     while (i<Length(UsersList)) and (ret = false) do
     begin

          if (username = UsersList[i].username) and (password = UsersList[i].password) and (UsersList[i].active = true) then
          begin
               ret       := true;
               directory := trim(UsersList[i].directory);
               id        := UsersList[i].id;
          end;

          Inc(i);
     end;

     result := ret;

end;

end.

