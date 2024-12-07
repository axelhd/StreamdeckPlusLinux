unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, DB, Forms, Controls, Graphics, Dialogs,
  DBGrids, StdCtrls, ActnList, Menus, ExtCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Dial0: TComboBox;
    DataSource1: TDataSource;
    DBConnection: TSQLite3Connection;
    Dial1: TComboBox;
    Dial2: TComboBox;
    Dial3: TComboBox;
    Memo1: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Dial0Change(Sender: TObject);
    procedure Dial0Click(Sender: TObject);
    procedure Dial1Change(Sender: TObject);
    procedure Dial1Click(Sender: TObject);
    procedure Dial2Change(Sender: TObject);
    procedure Dial2Click(Sender: TObject);
    procedure Dial3Change(Sender: TObject);
    procedure Dial3Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure SQLite3Connection1AfterConnect(Sender: TObject);
  private

  public

  end;



var
  Form1: TForm1;
  F: TField;
  {
  STATIC ARRAYS
  app: array[0..255] of String;
  media: array[0..255] of String;
  app_id: array[0..255] of integer;
  dial: array[0..3] of integer;
  }
  app: array of String;
  media: array of String;
  app_id: array of integer;
  dial: array of integer;
  app_media: array of String;

implementation

operator in(const a:string;b:Array Of String):integer;inline;
var i:integer;
begin
  Result := -1;
  for i :=Low(b) to High(b) do
  if a = b[i] then
    begin
      Result := i;
      Break;
    end;
end;

{$R *.lfm}

{ TForm1 }

procedure db_stuff();
var
  i: Integer;
  a: String;
  b: String;
  c: String;
  j: String;
begin
  Form1.SQLQuery1.Close;
  Form1.SQLQuery1.SQL.Text := 'SELECT * FROM sink';
  Form1.DBConnection.Connected := True;
  Form1.SQLTransaction1.Active := True;
  Form1.SQLQuery1.Open;
  {
  for F in SQLQuery1.Fields do begin
    Memo1.Append(F.AsString);
  end;

  Memo1.Append(SQLQuery1.Fields[0].AsString);
  }

  app := [];
  media := [];
  app_id := [];
  app_media := [];

  while not Form1.SQLQuery1.EOF do
    begin
    // Construct a line with all field values in the current row

    a := Form1.SQLQuery1.Fields[0].AsString;
    b := Form1.SQLQuery1.Fields[1].AsString;
    c := Form1.SQLQuery1.Fields[2].AsString;
    {
    Memo1.Lines.Add(a);
    Memo1.Lines.Add(b);
    Memo1.Lines.Add(c);
    Memo1.Lines.Add('');
    }
    insert(a, app, 255);
    insert(b, media, 255);
    insert(c.ToInteger, app_id, 255);
    insert(a + ': ' + b, app_media, 255);

    Form1.SQLQuery1.Next;

  end;
  Form1.SQLQuery1.Close;
  Form1.SQLTransaction1.Active := False;
  Form1.DBConnection.Connected := False;

  for j in app do
  begin
    Form1.Memo1.Lines.Add(j);
  end;

  Form1.Memo1.Lines.Add('');

  for j in media do
  begin
    Form1.Memo1.Lines.Add(j);
  end;

  Form1.Memo1.Lines.Add('');

  for i in app_id do
  begin
    Form1.Memo1.Lines.Add(i.ToString);
  end;
end;

procedure dial_stuff();
var
  s: String;
begin
  Form1.Dial0.Items.Clear;
  Form1.Dial1.Items.Clear;
  Form1.Dial2.Items.Clear;
  Form1.Dial3.Items.Clear;
  for s in app_media do
  begin
    Form1.Dial0.Items.Add(s);
    Form1.Dial1.Items.Add(s);
    Form1.Dial2.Items.Add(s);
    Form1.Dial3.Items.Add(s);
  end;
end;

procedure TForm1.SQLite3Connection1AfterConnect(Sender: TObject);
begin

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  db_stuff();
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  dial_stuff();
end;

procedure dial_select(index: integer; dial: integer);
var
  query: String;
begin
  //query := 'DELETE FROM selected WHERE dial = ' + dial.ToString;
  Form1.SQLQuery1.Close;
  Form1.SQLQuery1.SQL.Text := 'DELETE FROM selected WHERE dial = :dial';
  Form1.SQLQuery1.Params.ParamByName('dial').AsInteger := dial;
  Form1.Memo1.Lines.Append(Form1.SQLQuery1.SQL.Text);
  Form1.SQLQuery1.ExecSQL;
  Form1.SQLTransaction1.Commit;

  //query := 'INSERT INTO selected VALUES (''' + app[index] + ''', ''' + media[index] + ''', ' + app_id[index].ToString + ', ' + dial.ToString + ')';
  Form1.SQLQuery1.Close;
  Form1.SQLQuery1.SQL.Text := 'INSERT INTO selected VALUES (:app, :media, :id, :dial)';
  Form1.SQLQuery1.Params.ParamByName('app').AsString := app[index];   
  Form1.SQLQuery1.Params.ParamByName('media').AsString := media[index];
  Form1.SQLQuery1.Params.ParamByName('id').AsInteger := app_id[index];
  Form1.SQLQuery1.Params.ParamByName('dial').AsInteger := dial;
  Form1.Memo1.Lines.Append(Form1.SQLQuery1.SQL.Text);
  Form1.SQLQuery1.ExecSQL;
  Form1.SQLTransaction1.Commit
end;

procedure TForm1.Dial0Change(Sender: TObject);
begin
  dial_select(Dial0.ItemIndex, 0);
end;

procedure TForm1.Dial1Change(Sender: TObject);
begin
  dial_select(Dial1.ItemIndex, 1);
end;

procedure TForm1.Dial2Change(Sender: TObject);
begin
  dial_select(Dial2.ItemIndex, 2);
end;

procedure TForm1.Dial3Change(Sender: TObject);
begin
  dial_select(Dial3.ItemIndex, 3);
end;

procedure TForm1.Dial0Click(Sender: TObject);
begin
  db_stuff();
  dial_stuff();
end;

procedure TForm1.Dial1Click(Sender: TObject);
begin
  db_stuff();
  dial_stuff();
end;

procedure TForm1.Dial2Click(Sender: TObject);
begin
  db_stuff();
  dial_stuff();
end;

procedure TForm1.Dial3Click(Sender: TObject);
begin
  db_stuff();
  dial_stuff();
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SQLQuery1.Close;
  SQLTransaction1.Active := False;
  DBConnection.Connected := False;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  db_stuff();
  dial_stuff();
end;

end.

