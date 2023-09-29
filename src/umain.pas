unit uMain;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, httpdefs, fpHTTP, fpWeb, fpspreadsheet, fpstypes, fpsallformats, fpjson;

type

  { TFPWebModule1 }

  TFPWebModule1 = class(TFPWebModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure indexRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse; var Handled: Boolean);
    procedure loginRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse; var Handled: Boolean);
    procedure statusRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse; var Handled: Boolean);
  private
         function IsValidLogin(username : string; password : string; var id_user : string; var directory : string) : boolean;
         function ConvertXLS2Json(filename: string; var jArray: TJSONArray;
           var description: string): boolean;
  public

  end;

var
  FPWebModule1: TFPWebModule1;

const
  INPUT_FORMAT = sfUser;

implementation
uses
    ujwtabstract, uExtended_fphttpapp;

{$R *.lfm}

{ TFPWebModule1 }

procedure TFPWebModule1.DataModuleCreate(Sender: TObject);
begin

end;

procedure TFPWebModule1.indexRequest(Sender: TObject; ARequest: TRequest;
  AResponse: TResponse; var Handled: Boolean);
var
   action               : string;
   jwt                  : string;
   id_user              : string;
   directory            : string;
   version              : string;
   jData                : TJSONData;
   jObject              : TJSONObject;
   code                 : integer;
   description          : string;
   ret                  : string;
   jArray               : TJSONArray;
begin
     jwt      := ARequest.QueryFields.Values['jwt'];
     ret      := '';
     action   := ARequest.QueryFields.Values['action'];
     jObject  := TJSONObject.Create;
     jwt      := VerifiedJWT(TokenPassword,jwt,TokenMinExpired);
     if (jwt <> '') then
     begin
          id_user      := GetIdUser(TokenPassword,jwt);
          directory    := GetValue1(TokenPassword,jwt);
          version      := GetWebAppVersion(TokenPassword,jwt);

          if trim(directory) = '' then
             directory := trim(DIR_DEFAULT);

          if (FileExists(Location + DIR_FILES + System.DirectorySeparator + directory + System.DirectorySeparator + action + '.xls')) then
          begin
               if ConvertXLS2Json(Location + DIR_FILES + System.DirectorySeparator + directory + System.DirectorySeparator + action + '.xls', jArray, description)  then
               begin
                    code         := 0;
                    description  := '';
               end else begin
                  code         := 3;
                  jwt          := '';
                  ret          := '';
               end;
          end else begin
              code         := 2;
              description  := 'Invalid action';
              jwt          := '';
              ret          := '';
          end;

     end else begin
       code         := 1;
       description  := 'Invalid jwt';
       version      := '';
       jwt          := '';
       ret          := '';
     end;
     jObject:=TJSONObject.Create(['code',code,
                 'description',description,
                 'version',version,
                 'result', jArray,
                 'jwt',jwt]);
     jData := jObject;
     AResponse.Contents.Text := jData.FormatJSON;
     if Assigned(jData) then
        FreeAndNil(jData);
     if Assigned(jData) then
        FreeAndNil(jArray);
     Handled := true;
end;

procedure TFPWebModule1.loginRequest(Sender: TObject; ARequest: TRequest;
  AResponse: TResponse; var Handled: Boolean);
var
  username    : string;
  password    : string;
  id_user     : string;
  directory   : string;
  jData       : TJSONData;
  jObject     : TJSONObject;
  code        : integer;
  description : string;
  jwt         : string;
begin
     jObject  := TJSONObject.Create;
     username := ARequest.QueryFields.Values['username'];
     password := ARequest.QueryFields.Values['password'];
     if (IsValidLogin(username, password, id_user, directory)) then
     begin
          code         := 0;
          description  := '';
          jwt          := GetJwt(TokenPassword, id_user, directory, '', '', '', TokenMinExpired);
     end else begin
       code         := 1;
       description  := 'Invalid login';
       jwt          := '';
     end;
     jObject:=TJSONObject.Create(['code',code,
                      'description',description,
                      'jwt',jwt]);
     jData := jObject;
     AResponse.Contents.Text := jData.FormatJSON;
     FreeAndNil(jData);
     Handled := true;
end;

procedure TFPWebModule1.statusRequest(Sender: TObject; ARequest: TRequest;
  AResponse: TResponse; var Handled: Boolean);
var
   jObject     : TJSONObject;
   jData       : TJSONData;
begin
     jObject:=TJSONObject.Create(['code',0,
                      'description','',
                      'status','online']);
     jData := jObject;
     AResponse.Contents.Text:=jData.FormatJSON;
     FreeAndNil(jData);
     Handled := true;
end;

function TFPWebModule1.IsValidLogin(username: string; password: string;
  var id_user: string; var directory: string): boolean;
var
   ret : boolean;
begin
     if ExistsValidUser(username, password, id_user, directory) then
     begin
          ret := true;
          if (trim(directory) = '') then
             directory := trim(DIR_DEFAULT);
     end else begin
          ret       := false;
          id_user   := '';
          directory := '';
     end;
     result := ret;
end;

function TFPWebModule1.ConvertXLS2Json(filename: string; var jArray : TJSONArray; var description : string): boolean;
var
   ret         : boolean;
   MyWorkbook  : TsWorkbook;
   MyWorksheet : TsWorksheet;
   col, row    : Cardinal;
   cell        : PCell;
   jObject     : TJSONObject;
   cellname    : string;
   cellvalue   : string;
begin
     ret        := false;
     MyWorkbook := TsWorkbook.Create;
     try
        try
           MyWorkbook.Options := MyWorkbook.Options + [boReadFormulas];
           MyWorkbook.ReadFromFile(filename, sfExcel8);
           MyWorksheet := MyWorkbook.GetFirstWorksheet();

           jArray := TJsonArray.Create;
           for row:=0 to MyWorksheet.GetLastRowIndex do
           begin
                if row = 0 then
                begin
                     //salto perchè la prima riga del file deve sempre contenere il nome della colonna.
                end else begin
                   jObject := TJSONOBject.Create;
                   for col := 0 to MyWorksheet.GetLastColIndex do
                   begin
                        cell := MyWorksheet.FindCell(0, col);
                        cellname := trim(MyWorksheet.ReadAsUTF8Text(cell));
                        cellname := StringReplace(StringReplace(cellname,#13,'', [rfReplaceAll]),#10,'', [rfReplaceAll]);
                        cell := MyWorksheet.FindCell(row, col);
                        cellvalue := MyWorksheet.ReadAsUTF8Text(cell);
                        cellvalue := StringReplace(StringReplace(cellvalue,#13,'', [rfReplaceAll]),#10,'', [rfReplaceAll]);
                        jObject.Strings[cellname] := cellvalue;
                   end;
                   jArray.Add(jObject);
                end;
           end;
           ret   := true;

        finally
               if Assigned(MyWorkbook) then
                  MyWorkbook.Free;
       end;
     except
           on E: Exception do
           begin

              description := E.Message;

           end;
     end;
     result := ret;
end;

initialization
  RegisterHTTPModule('TFPWebModule1', TFPWebModule1);
end.

