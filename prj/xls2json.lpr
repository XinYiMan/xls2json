program xls2json;

{$mode objfpc}{$H+}

uses
{$IFDEF UNIX}{$IFDEF UseCThreads}
cthreads,
{$ENDIF}{$ENDIF}
opensslsockets, fphttpapp,
uExtended_fphttpapp, sysutils,uMain;

{ https://blog.lazaruspascal.it/2023/05/18/creare-un-web-server-https/  }

var
application_path : string;
begin

application_path := ExtractFilePath(paramStr(0));

if not DirectoryExists(application_path + DIR_FILES) then
   CreateDir(application_path + DIR_FILES);

if not DirectoryExists(application_path + DIR_FILES + System.DirectorySeparator + DIR_DEFAULT) then
   CreateDir(application_path + DIR_FILES + System.DirectorySeparator + DIR_DEFAULT);

LoadConfigIni(application_path, 'config.ini');

Application.Title := 'Xls2Json Web Service - created by Sammarco Francesco';
Application.Port  := Application_port;
Application.Threaded := True;
Application.UseSSL := Application_with_ssl;
Application.LegacyRouting := True;
Application.HTTPhandler.HTTPServer.CertificateData.Certificate.FileName := CertificatePath;
Application.HTTPhandler.HTTPServer.CertificateData.PrivateKey.FileName := PrivateKeyPath;
if not Application_with_ssl then
   writeln('http://localhost:', Application.Port, '/TFPWebModule1/index')
else
    writeln('https://localhost:', Application.Port, '/TFPWebModule1/index');
writeln('Configuration from ' + application_path + 'config.ini file');
writeln(Application.Title);
Application.Initialize;
Application.Run;
end.

