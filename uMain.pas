unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, StrUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Grids, ComCtrls, Buttons, ExtCtrls, Menus, ECSwitch, FileUtil,
  Types;

type

  { TFMain }

  TFMain = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ECSwitch1: TECSwitch;
    GroupBox1: TGroupBox;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    ImageList1: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    op: TOpenDialog;
    grid: TStringGrid;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ECSwitch1Change(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure FormShow(Sender: TObject);
    procedure gridButtonClick(Sender: TObject; aCol, aRow: Integer);
    procedure gridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect;
      aState: TGridDrawState);
    procedure gridPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure Image1Click(Sender: TObject);
    procedure Image2Click(Sender: TObject);
    procedure Image3Click(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    procedure ConvertPDFToImage(const PDFFile, OutputDir: string;
      Format: Integer);
    function MergePDFsWithPdfUnite(const InputFiles: array of string;
      const OutputFile: string; out ErrorMessage: string): Boolean;
    function SplitPDFWithPdfSeparate(const InputFile, OutputPattern: string;
      out PageCount: Integer; out ErrorMessage: string): Boolean;

  public

  end;

var
  FMain: TFMain;

implementation


{$R *.lfm}

{ TFMain }

function TFMain.SplitPDFWithPdfSeparate(const InputFile, OutputPattern: string;
  out PageCount: Integer; out ErrorMessage: string): Boolean;
var
  Process: TProcess;
  OutputList: TStringList;
  i: Integer;
begin
  Result := False;
  PageCount := 0;
  ErrorMessage := '';

  // Validasi input
  if not FileExists(InputFile) then
  begin
    ErrorMessage := 'File input tidak ditemukan: ' + InputFile;
    Exit;
  end;

  // Cari lokasi pdfseparate.exe
  if not FileExists('pdfseparate.exe') then
  begin
    ErrorMessage := 'pdfseparate.exe tidak ditemukan. Pastikan Poppler terinstal.';
    Exit;
  end;

  // Buat proses
  Process := TProcess.Create(nil);
  OutputList := TStringList.Create;
  try
    Process.Executable := 'pdfseparate.exe';
    Process.Parameters.Add(InputFile);
    Process.Parameters.Add(OutputPattern);
    //Process.Parameters.Add(getcurrentdir+'\split.pdf');
    Process.Options := [poWaitOnExit, poUsePipes, poStderrToOutPut];
    Process.ShowWindow := swoHIDE;

    try
      // Jalankan proses
      Process.Execute;

      // Baca output error jika ada


      // Hitung jumlah halaman yang berhasil dipisahkan
      PageCount := 0;
      for i := 1 to MaxInt do
      begin
        if FileExists(ReplaceStr(OutputPattern, '%d', IntToStr(i))) then
          Inc(PageCount)
        else
          Break;
      end;

      Result := PageCount > 0;
      if not Result then
        ErrorMessage := 'Tidak ada halaman yang berhasil dipisahkan';
    except
      on E: Exception do
        ErrorMessage := 'Error saat menjalankan pdfseparate: ' + E.Message;
    end;
  finally
    OutputList.Free;
    Process.Free;
  end;
end;

function TFMain.MergePDFsWithPdfUnite(const InputFiles: array of string;
  const OutputFile: string; out ErrorMessage: string): Boolean;
var
  Process: TProcess;
  i: Integer;
  CmdLine: string;
begin
  Result := False;
  ErrorMessage := '';

  // Validasi input
  if Length(InputFiles) < 2 then
  begin
    ErrorMessage := 'Minimal diperlukan 2 file PDF untuk digabungkan';
    Exit;
  end;

  // Cari lokasi pdfunite.exe (sesuaikan dengan path instalasi Anda)
  if not FileExists('pdfunite.exe') then
  begin
    // Coba cari di path sistem

  end
  else
    CmdLine := 'pdfunite.exe';
  // Buat proses
  Process := TProcess.Create(nil);
  try
    Process.Executable := CmdLine;
    Process.Options := [poWaitOnExit, poUsePipes, poStderrToOutPut];
    Process.ShowWindow := swoHIDE;

    // Tambahkan parameter: file input dan output
    for i := 0 to High(InputFiles) do
    begin
      if not FileExists(InputFiles[i]) then
      begin
        ErrorMessage := Format('File tidak ditemukan: %s', [InputFiles[i]]);
       // Exit;
      end;
      Process.Parameters.Add(InputFiles[i]);
    end;

    Process.Parameters.Add(OutputFile);

    try
      // Jalankan proses
      Process.Execute;

      // Baca output error jika ada
      if Process.ExitStatus <> 0 then
      begin
        ErrorMessage := 'Proses pdfunite gagal: ';
        Exit;
      end;

      Result := FileExists(OutputFile);
      if not Result then
        ErrorMessage := 'File output tidak berhasil dibuat';
    except
      on E: Exception do
        ErrorMessage := 'Error saat menjalankan pdfunite: ' + E.Message;
    end;
  finally
    Process.Free;
  end;
end;



procedure TFMain.ConvertPDFToImage(const PDFFile, OutputDir: string; Format: Integer);
var
  AProcess: TProcess;
  OutputPrefix: string;
  OutputExt: string;
begin
  if not FileExists(PDFFile) then
  begin
    ShowMessage('File PDF tidak ditemukan!');
    Exit;
  end;

  if not DirectoryExists(OutputDir) then
    ForceDirectories(OutputDir);

  AProcess := TProcess.Create(nil);
  try
    OutputPrefix := IncludeTrailingPathDelimiter(OutputDir) +
                   ChangeFileExt(ExtractFileName(PDFFile), '');

    case Format of
      0: begin // JPEG
           OutputExt := 'jpg';
           AProcess.Executable := 'pdftoppm';
           AProcess.Parameters.Add('-jpeg');
         end;
      1: begin // PNG
           OutputExt := 'png';
           AProcess.Executable := 'pdftocairo';
           AProcess.Parameters.Add('-png');
         end;
    end;

    AProcess.Parameters.Add(PDFFile);
    AProcess.Parameters.Add(OutputPrefix);
    AProcess.Options := AProcess.Options + [poWaitOnExit];
    AProcess.ShowWindow := swoHIDE;

    //lblStatus.Caption := 'Mengkonversi...';
    Application.ProcessMessages;

    AProcess.Execute;

    //lblStatus.Caption := 'Konversi selesai!';
    //UpdateImageList(OutputDir);
  finally
    AProcess.Free;
  end;
end;

procedure TFMain.Button1Click(Sender: TObject);
begin
if op.Execute then begin
   ConvertPDFToImage(op.FileName,extractfilepath(op.FileName),0);

   memo1.Lines.Add('File converted to image');

end;

end;

procedure TFMain.Button2Click(Sender: TObject);
var strs : array of string;
  str:string;
  i : integer;
begin
if op.Execute then begin
   for i:= 0 to (op.Files.Count-1) do begin
     SetLength(strs,op.Files.Count);
       strs[i] := op.Files[i];
   end;
   MergePDFsWithPdfUnite(strs,extractfilepath(op.FileName)+'\merge.pdf',str);
   memo1.Lines.Add('File merged on : '+extractfilepath(op.FileName));
   memo1.Lines.Add(str);
end;

end;

procedure TFMain.Button3Click(Sender: TObject);
var PageCount: Integer;
  ErrorMsg: string;
  InitDir, DestDir : string;
  i : integer;
begin
if op.Execute then begin
   InitDir := ExtractFilePath(Application.ExeName);
   DestDir := ExtractFilePath(op.FileName);
   SplitPDFWithPdfSeparate(op.FileName,'%d_Split_'+extractfilename(op.FileName),PageCount,ErrorMsg);
   for i := 1 to PageCount do begin
       CopyFile(InitDir+'\'+IntToStr(i)+'_Split_'+extractfilename(op.FileName),
       DestDir+'\'+IntToStr(i)+'_Split_'+extractfilename(op.FileName));
       DeleteFile(InitDir+'\'+IntToStr(i)+'_Split_'+extractfilename(op.FileName));
       memo1.Lines.Add('File splitted');
   end;
end;
end;

procedure TFMain.ECSwitch1Change(Sender: TObject);
begin
  if ECSwitch1.Checked then self.FormStyle:= fsSystemStayOnTop else self.FormStyle:= fsNormal;
end;

procedure TFMain.FormDropFiles(Sender: TObject; const FileNames: array of string
  );
var i : integer;
begin
for i := 0 to high(filenames) do begin
    if ExtractFileExt(filenames[i])='.pdf' then begin
    grid.RowCount:=(grid.RowCount)+1;
    grid.Cells[0,grid.RowCount-1]:= filenames[i];

    end;
end;

end;

procedure TFMain.FormShow(Sender: TObject);
begin
  self.Left:= screen.Width-self.Width-20;
  image1.Width:=image1.Height;
  image2.Width:=image2.Height;
end;

procedure TFMain.gridButtonClick(Sender: TObject; aCol, aRow: Integer);
begin
  grid.DeleteRow(grid.Row);
end;

procedure TFMain.gridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
begin
if (acol = 1) and (arow>0) then begin
   imagelist1.Draw(grid.Canvas, aRect.Left+3, aRect.Top+0, ARow mod ImageList1.Count);
end;

end;

procedure TFMain.gridPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
begin
  //if (arow>1) then grid.FixedColor:=clWhite;
end;

procedure TFMain.Image1Click(Sender: TObject);
var strs : array of string;
  str:string;
  i : integer;
begin
If grid.RowCount=1 then begin
   memo1.Lines.Add('No PDF files found');
   exit;
   end;
if grid.RowCount>0 then begin
   for i:= 1 to grid.RowCount-1 do begin
       SetLength(strs,grid.RowCount);
       strs[i] := grid.Cells[0,i];
   end;
   MergePDFsWithPdfUnite(strs,extractfilepath(grid.Cells[0,1])+'merge.pdf',str);
   if fileexists(extractfilepath(grid.Cells[0,1])+'\merge.pdf') then
   memo1.Lines.Add('Merge Success : '+extractfilepath(grid.Cells[0,1])+'merge.pdf');
end;

end;

procedure TFMain.Image2Click(Sender: TObject);
var strs : array of string;
  str:string;
  i,ii,pagecount : integer;
  InitDir,DestDir,ErrorMsg : string;
begin
If grid.RowCount=1 then begin
   memo1.Lines.Add('No PDF files found');
   exit;
   end;
if grid.RowCount>0 then begin
   for i:= 1 to grid.RowCount-1 do begin
       InitDir := ExtractFilePath(application.ExeName);
       DestDir := ExtractFilePath(grid.Cells[0,i]);
   SplitPDFWithPdfSeparate(grid.Cells[0,i],'%d_Split_'+extractfilename(grid.Cells[0,i]),PageCount,ErrorMsg);
   for ii := 1 to PageCount do begin
       CopyFile(InitDir+'\'+IntToStr(ii)+'_Split_'+extractfilename(grid.Cells[0,i]),
       DestDir+'\'+IntToStr(ii)+'_Split_'+extractfilename(grid.Cells[0,i]));
       DeleteFile(InitDir+'\'+IntToStr(ii)+'_Split_'+extractfilename(grid.Cells[0,i]));
       memo1.Lines.Add('File splitted '+DestDir+'\'+IntToStr(ii)+'_Split_'+extractfilename(grid.Cells[0,i]));
     end;
   end;


end;

end;

procedure TFMain.Image3Click(Sender: TObject);
var strs : array of string;
  str:string;
  i : integer;
begin
If grid.RowCount=1 then begin
   memo1.Lines.Add('No PDF files found');
   exit;
   end;
if grid.RowCount>0 then begin
   for i:= 1 to grid.RowCount-1 do begin
       ConvertPDFToImage(grid.Cells[0,i],extractfilepath(grid.Cells[0,i]),0);
       memo1.Lines.Add('Pdf converted to Image '+extractfilepath(grid.Cells[0,i])+extractfilename(grid.Cells[0,i]));
   end;

end;

end;

procedure TFMain.MenuItem1Click(Sender: TObject);
begin
  showmessage('[Freeware] - No Warrant - You must use with your own risk'+#13+
  'Implementation of Poppler pdf rendering library.'+#13+
  'Didi K.'+#13+
  'didikuriad@gmail.com'+#13+
  'Made by Lazarus'+#13+
  'Pascal Coding with ease');
end;

procedure TFMain.SpeedButton1Click(Sender: TObject);
begin


end;

end.

