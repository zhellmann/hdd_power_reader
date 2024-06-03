unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, ComCtrls, ExtCtrls, StdCtrls, SysUtils, FileUtil, Forms, Controls,
  Graphics, Dialogs, Buttons, ActnList, DataPortSerial, DataPort,
  LCLType, LCLIntf, IntfGraphics, XMLPropStorage, TAGraph, TASeries, TACustomSeries;

type
  { TFormMain }

  TFormMain = class(TForm)
    actConnect: TAction;
    alMain: TActionList;
    btnSerialConnect: TBitBtn;
    cbMarksCurrent: TComboBox;
    cbSeriesVoltage: TComboBox;
    cbSaveCurrent: TComboBox;
    cbMarksVoltage: TComboBox;
    cbSerialBitrate: TComboBox;
    cbMeasureTime: TComboBox;
    cbSerialPort: TComboBox;
    cbSaveVoltage: TComboBox;
    cbSeriesCurrent: TComboBox;
    lbMarksVoltage: TLabel;
    chSeries12A: TLineSeries;
    chSeries5A: TLineSeries;
    chVoltage: TChart;
    chSeries12V: TLineSeries;
    chSeries5V: TLineSeries;
    chCurrent: TChart;
    dpSerial: TDataPortSerial;
    lbMarksCurrent: TLabel;
    lbSeriesVoltage: TLabel;
    lbSaveCurrent: TLabel;
    lbSerialBitrate: TLabel;
    lbSaveVoltage: TLabel;
    lbSeriesCurrent: TLabel;
    LCountdown: TLabel;
    lbSerialPort: TLabel;
    chFast: TChart;
    chFastConstantLine1: TConstantLine;
    chFastLineSeries1: TLineSeries;
    lbMeasureTime: TLabel;
    memoTerminal: TMemo;
    PageControl1: TPageControl;
    pnlConfiguration: TPanel;
    pnlVoltage: TPanel;
    pnlCurrent: TPanel;
    SaveDialog1: TSaveDialog;
    tsCurrent: TTabSheet;
    Timer1: TTimer;
    tsVoltage: TTabSheet;
    tsConfiguration: TTabSheet;
    XMLPropStorage1: TXMLPropStorage;
    procedure cbMarksCurrentChange(Sender: TObject);
    procedure cbMarksVoltageChange(Sender: TObject);
    procedure cbSaveCurrentChange(Sender: TObject);
    procedure cbSaveVoltageChange(Sender: TObject);
    procedure cbSeriesCurrentChange(Sender: TObject);
    procedure cbSeriesVoltageChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure actConnectExecute(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure XMLPropStorage1RestoreProperties(Sender: TObject);
    procedure XMLPropStorage1SavingProperties(Sender: TObject);
  private
    { private declarations }
    FDataPort: TDataPort;
    procedure SetDataPort(AValue: TDataPort);
    procedure UpdateSerialPortList();
    procedure AppendToTerminal(const s: string);
    procedure OnDataAppearHandler(Sender: TObject);
    procedure OnErrorHandler(Sender: TObject; const AMsg: string);
    procedure OnOpenHandler(Sender: TObject);
    procedure OnCloseHandler(Sender: TObject);
    function GetFileName(const AExt: String): String;
  public
    { public declarations }
    property DataPort: TDataPort read FDataPort write SetDataPort;
  end;

var
  FormMain: TFormMain;
  serialData: TStringList;
  measureTime: integer;
  arrPorts: array [0..5] of integer = (300, 1200, 9600, 19200, 57600, 115200);
  arrTime: array [0..5] of integer = (5, 10, 20, 30, 45, 60);

implementation

{$R *.lfm}

{ TFormMain }

procedure TFormMain.UpdateSerialPortList();
var
  sl: TStringList;
begin
  cbSerialPort.Items.Clear();
  sl := TStringList.Create();
  try
    sl.CommaText := dpSerial.GetSerialPortNames();
    cbSerialPort.Items.AddStrings(sl);
  finally
    sl.Free();
  end;

  if cbSerialPort.Items.Count > 0 then
    cbSerialPort.ItemIndex := 0
  else
    cbSerialPort.Text := '';
end;

procedure TFormMain.SetDataPort(AValue: TDataPort);
begin
  if FDataPort = AValue then Exit;

  if Assigned(FDataPort) then
  begin
    FDataPort.Close();
    FDataPort.OnOpen := nil;
    FDataPort.OnClose := nil;
    FDataPort.OnDataAppear := nil;
    FDataPort.OnError := nil;
    FDataPort := nil;
  end;

  FDataPort := AValue;

  if Assigned(FDataPort) then
  begin
    FDataPort.OnOpen := @OnOpenHandler;
    FDataPort.OnClose := @OnCloseHandler;
    FDataPort.OnDataAppear := @OnDataAppearHandler;
    FDataPort.OnError := @OnErrorHandler;
  end;
end;

procedure TFormMain.AppendToTerminal(const s: string);
begin
  memoTerminal.Lines.BeginUpdate();
  memoTerminal.Text := memoTerminal.Text + s;
  if memoTerminal.Lines.Count > 1200 then
  begin
    while memoTerminal.Lines.Count > 1000 do
      memoTerminal.Lines.Delete(0);
  end;
  memoTerminal.SelStart := MaxInt;
  memoTerminal.Lines.EndUpdate();
  memoTerminal.ScrollBy(0, -100000);
end;

procedure TFormMain.OnDataAppearHandler(Sender: TObject);
begin
  serialData.Clear;
  serialData.DelimitedText := DataPort.Pull();

  //AppendToTerminal(serialData.DelimitedText);
  if (serialData.Count > 4) then            // list of separated items
  begin
    if (StrToFloatDef(serialData.Strings[2], 0) < 0) then serialData.Strings[2] := '0';   // correction if measured current is negative
    if (StrToFloatDef(serialData.Strings[3], 0) < 0) then serialData.Strings[3] := '0';
    AppendToTerminal('12V: ' + serialData.Strings[0] + '  5V: '  + serialData.Strings[1] + '  12A: ' + serialData.Strings[2] + '  5A: ' + serialData.Strings[3] + ' [' + serialData.Strings[4] + ']' + #13#10);
    chSeries12V.AddXY(StrToFloatDef(serialData.Strings[4], 0)/1000, StrToFloatDef(serialData.Strings[0], 0));
    chSeries5V.AddXY(StrToFloatDef(serialData.Strings[4], 0)/1000, StrToFloatDef(serialData.Strings[1], 0));
    chSeries12A.AddXY(StrToFloatDef(serialData.Strings[4], 0)/1000, StrToFloatDef(serialData.Strings[2], 0));
    chSeries5A.AddXY(StrToFloatDef(serialData.Strings[4], 0)/1000, StrToFloatDef(serialData.Strings[3], 0));
  end;
end;

procedure TFormMain.OnErrorHandler(Sender: TObject; const AMsg: string);
begin
  actConnect.Caption := 'Connect';
  ShowMessage(AMsg + sLineBreak);
end;

procedure TFormMain.OnOpenHandler(Sender: TObject);
var
  i: integer;
begin
  memoTerminal.Clear();                              // clear terminal
  for i:=0 to chVoltage.SeriesCount-1 do             // clear chart
    if chVoltage.Series[i] is TChartSeries then
      TChartSeries(chVoltage.Series[i]).Clear;
  for i:=0 to chCurrent.SeriesCount-1 do             // clear chart
    if chCurrent.Series[i] is TChartSeries then
      TChartSeries(chCurrent.Series[i]).Clear;

  measureTime := StrToInt(cbMeasureTime.Text);
  Timer1.Enabled := True;
  actConnect.Caption := 'Disconnect';
end;

procedure TFormMain.OnCloseHandler(Sender: TObject);
begin
  Timer1.Enabled := False;
  LCountdown.Caption := '';
  actConnect.Caption := 'Connect';
end;

function TFormMain.GetFileName(const AExt: String): String;
begin
  with SaveDialog1 do begin
    FileName := '';
    DefaultExt := AExt;
    Filter := UpperCase(AExt) + '|*.' + AExt;
    if not Execute then Abort;
    Result := FileName;
  end;
end;


procedure TFormMain.FormCreate(Sender: TObject);
var
  i: integer;
begin
  Constraints.MinWidth := 400;              // minimal window size
  Constraints.MinHeight := 400;
  DefaultFormatSettings.DecimalSeparator := '.';       // needed for drawing
  memoTerminal.Clear();
  serialData := TStringList.Create;
  serialData.StrictDelimiter := True;
  serialData.Delimiter := '|';
  SaveDialog1.InitialDir := ExtractFilePath(Application.ExeName);

  DataPort := dpSerial;                     // bitrates
  UpdateSerialPortList();

  for i := Low(arrPorts) to High(arrPorts) do       // fill Bitrate combobox
    cbSerialBitrate.Items.Add(IntToStr(arrPorts[i]));
  cbSerialBitrate.ItemIndex := 2;                   // default bitrate (9600)

  for i := Low(arrTime) to High(arrTime) do         // fill Measure time combobox
    cbMeasureTime.Items.Add(IntToStr(arrTime[i]));
  cbMeasureTime.ItemIndex := 2;                     // default measure time (10)
end;

procedure TFormMain.cbSaveVoltageChange(Sender: TObject);
begin
  case cbSaveVoltage.ItemIndex of
  1 : chVoltage.SaveToBitmapFile(GetFileName('bmp'));
  2 : chVoltage.SaveToFile(TJPEGImage, GetFileName('jpg'));
  3 : chVoltage.SaveToFile(TPortableNetworkGraphic, GetFileName('png'));
  4 : chVoltage.CopyToClipboardBitmap;
  end;
end;

procedure TFormMain.cbSeriesCurrentChange(Sender: TObject);
begin
  if (cbSeriesCurrent.ItemIndex = 1) then           // 12V
  begin
    chSeries12A.Active := True;
    chSeries5A.Active := False;
  end
  else if (cbSeriesCurrent.ItemIndex = 2) then      // 5V
  begin
    chSeries12A.Active := False;
    chSeries5A.Active := True;
  end
  else
  begin
    chSeries12A.Active := True;            // Both
    chSeries5A.Active := True;
  end;
end;

procedure TFormMain.cbSeriesVoltageChange(Sender: TObject);
begin
  if (cbSeriesVoltage.ItemIndex = 1) then           // 12V
  begin
    chSeries12V.Active := True;
    chSeries5V.Active := False;
  end
  else if (cbSeriesVoltage.ItemIndex = 2) then      // 5V
  begin
    chSeries12V.Active := False;
    chSeries5V.Active := True;
  end
  else
  begin
    chSeries12V.Active := True;            // Both
    chSeries5V.Active := True;
  end;
end;

procedure TFormMain.cbSaveCurrentChange(Sender: TObject);
begin
  case cbSaveCurrent.ItemIndex of
  1 : chCurrent.SaveToBitmapFile(GetFileName('bmp'));
  2 : chCurrent.SaveToFile(TJPEGImage, GetFileName('jpg'));
  3 : chCurrent.SaveToFile(TPortableNetworkGraphic, GetFileName('png'));
  4 : chCurrent.CopyToClipboardBitmap;
  end;
end;

procedure TFormMain.cbMarksVoltageChange(Sender: TObject);
begin
  if (cbMarksVoltage.ItemIndex = 1) then           // 12V
  begin
    chSeries12V.Marks.Visible := True;
    chSeries5V.Marks.Visible := False;
  end
  else if (cbMarksVoltage.ItemIndex = 2) then      // 5V
  begin
    chSeries12V.Marks.Visible := False;
    chSeries5V.Marks.Visible := True;
  end
  else if (cbMarksVoltage.ItemIndex = 3) then      // Both
  begin
    chSeries12V.Marks.Visible := True;
    chSeries5V.Marks.Visible := True;
  end
  else
  begin
    chSeries12V.Marks.Visible := False;            // None
    chSeries5V.Marks.Visible := False;
  end;
end;

procedure TFormMain.cbMarksCurrentChange(Sender: TObject);
begin
  if (cbMarksCurrent.ItemIndex = 1) then           // 12V
  begin
    chSeries12A.Marks.Visible := True;
    chSeries5A.Marks.Visible := False;
  end
  else if (cbMarksCurrent.ItemIndex = 2) then      // 5V
  begin
    chSeries12A.Marks.Visible := False;
    chSeries5A.Marks.Visible := True;
  end
  else if (cbMarksCurrent.ItemIndex = 3) then      // Both
  begin
    chSeries12A.Marks.Visible := True;
    chSeries5A.Marks.Visible := True;
  end
  else
  begin
    chSeries12A.Marks.Visible := False;            // None
    chSeries5A.Marks.Visible := False;
  end;
end;

procedure TFormMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  serialData.Free;
end;

procedure TFormMain.actConnectExecute(Sender: TObject);
begin
  if not Assigned(DataPort) then Exit;
  if DataPort.Active then
  begin
    DataPort.Close();
  end
  else
  begin
    dpSerial.Port := cbSerialPort.Text;
    dpSerial.BaudRate := StrToIntDef(cbSerialBitrate.Text, 9600);
    actConnect.Caption := 'Connecting..';
    DataPort.Open();
  end;
end;

procedure TFormMain.Timer1Timer(Sender: TObject);
begin
  LCountdown.Caption := Format('%ds',[measureTime]);         // Measure time counter
  Dec(measureTime);
  if (measureTime < 0) then
  begin
    Timer1.Enabled := False;
    LCountdown.Caption := 'OK';
    if DataPort.Active then
      DataPort.Close();
  end;
end;

procedure TFormMain.XMLPropStorage1RestoreProperties(Sender: TObject);
var
  i, tmp: integer;
  Found: boolean;
begin
  Found := false;
  tmp := StrToIntDef(XMLPropStorage1.StoredValue['bitrate'], 9600);
  for i := Low(arrPorts) to High(arrPorts) do    // check if loaded value is correct
    if arrPorts[i] = tmp then
    begin
      Found := true;
      cbSerialBitrate.Text := IntToStr(tmp);
      break;
    end;

   if not Found then                             // default bitrate if loaded is not correct
     cbSerialBitrate.ItemIndex := 2;

   Found := false;
   tmp := StrToIntDef(XMLPropStorage1.StoredValue['measuretime'], 10);
   for i := Low(arrTime) to High(arrTime) do     // check if loaded value is correct
     if arrTime[i] = tmp then
     begin
       Found := true;
       cbMeasureTime.Text := IntToStr(tmp);
       break;
     end;

    if not Found then                            // default measure time if loaded is not correct
      cbMeasureTime.ItemIndex := 2;
end;

procedure TFormMain.XMLPropStorage1SavingProperties(Sender: TObject);
begin
  XMLPropStorage1.StoredValue['bitrate'] := cbSerialBitrate.Text;
  XMLPropStorage1.StoredValue['measuretime'] := cbMeasureTime.Text;
end;

end.

