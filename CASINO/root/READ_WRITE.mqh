#include "TRADING_NEW.mqh"
#include "/MASTER_INDI.mqh"
struct SETTING
{
    int    row_idx;
    string Pair;
    double Amplitude;
    double Fix_Tp;
    double RSIPer;
    double LotExponent;
    int    MagicNumber;
    double Entry_Percent;
    SETTING() : row_idx(0), Pair(""), Amplitude(0), Fix_Tp(0), RSIPer(0), LotExponent(0), MagicNumber(0), Entry_Percent(0)  {}; 
};

struct INDICATOR
{
    datetime date;
    double   value;
    INDICATOR() : date(0), value(0)  {}; 
};

struct HEDGE_CONFIG
{
     bool blHedgeTag;
     bool blHedgeBreakEven;
     int  intHedgeInitiator;
     HEDGE_CONFIG() : blHedgeTag(false), blHedgeBreakEven(false), intHedgeInitiator(0) {};
};

class clsConfig 
{
      public:
                      clsConfig();
                      ~clsConfig();
        void          Oninit();
        void          ReadConfig();
        void          WriteData(string input_file_name, string header, string data, bool insert_end=true);
        void          ReadData(string input_file_name, string &data[]);
        void          ReadHedgeData(string input_file_name, HEDGE_CONFIG &HEDGE);
        void          WriteHedgeData(string file_name, string to_write);
        void          ReadIndicator(string input_file_name);
        bool          MatchDate(datetime datetime_1, datetime datetime_2);
        void          WriteTradeList(string symbol, TRADE_LIST &trades[]);
        void          ReadTradeList(string symbol, TRADE_LIST &trades[]);
        string        BoolToString(bool InpBool);
        SETTING       config_settings[];
        INDICATOR     indicators[];
        clsMasterIndi *INDI;
        
      
      protected:
        bool         DuplicateTradeCheck(int ticket, TRADE_LIST &trades[]);
        bool         StrToBool(string strInpString);
        
      private:
        bool         blCommonFlag;
        int          intFileHandle;
        string       strConfigFileName;
        string       strFolderPath();
        
};

void clsConfig::clsConfig(void)
{
     this.Oninit();
     INDI = new clsMasterIndi(ChartSymbol(),PERIOD_M1);
}

void clsConfig::~clsConfig(void)
{
     if(CheckPointer(INDI) == POINTER_DYNAMIC) delete(INDI);
}

void clsConfig::Oninit(void)
{
     this.blCommonFlag = false;
     this.strConfigFileName = "TEST_EA.csv";
     this.ReadConfig();
}

string clsConfig::strFolderPath()
{
   string working_folder;
   if(this.blCommonFlag)
      working_folder=TerminalInfoString(TERMINAL_COMMONDATA_PATH)+"\\MQL4\\Files";
   else
      working_folder=TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL4\\Files";
   return(working_folder);
}

bool clsConfig::MatchDate(datetime datetime_1, datetime datetime_2)
{
   if(TimeDay(datetime_1)   == TimeDay(datetime_2) &&
      TimeMonth(datetime_1) == TimeMonth(datetime_2) &&
      TimeYear(datetime_1)  == TimeYear(datetime_2) 
     )
   {
       return(true);
   }
   return(false);
}

bool clsConfig::StrToBool(string strInpString)
{
   bool value = false;
   if(strInpString == "true" || strInpString == "True" || strInpString == "TRUE")
   {
      value = true;
   }
   return(value);
}

string clsConfig::BoolToString(bool InpBool)
{
   string value = "False";
   if(InpBool) {value = "True";}
   return(value);
}

void clsConfig::ReadTradeList(string symbol, TRADE_LIST &trades[])
{
   string file_name = symbol+"_TRADES.csv";
   Print("Preparing To Read Saved Trades");
   if(FileIsExist(file_name,this.blCommonFlag))
   {
        //Print("Trade File Present");
        int row = 0; int col = 0;
        //we read config
        int read_handle = FileOpen(file_name,FILE_READ|FILE_CSV);
        if(read_handle == INVALID_HANDLE) Print(file_name," is in Used, Please Close");
        TRADE_LIST tmp_trade;
        while(!FileIsEnding(read_handle))
        {
            //Print("Hey");
            string value = FileReadString(read_handle);
            //Print(value);
            
            switch (col)
            {
                case 0:
                   //Alert("Active value is ",value);
                   tmp_trade._active = StrToBool(value);
                   //Alert("Post Convert Active value is ",tmp_trade._active);
                   break;
                case 1:
                   tmp_trade._order_type = StrToInteger(value);
                   break;
                case 2:
                   tmp_trade._ticket_number = StrToInteger(value);
                   break;
                case 3:
                   tmp_trade._order_symbol = value;
                   break;
                case 4:
                   tmp_trade._order_lot = StrToDouble(value);
                   break;
                case 5:
                   tmp_trade._open_price = StrToDouble(value);
                   break;
                case 6:
                   tmp_trade._close_price = StrToDouble(value);
                   break;
                case 7:
                   tmp_trade._entry = StrToDouble(value);
                   break;
                case 8:
                   tmp_trade._stop_loss = StrToDouble(value);
                   break;
                case 9:
                   tmp_trade._take_profit = StrToDouble(value);
                   break;
                case 10:
                   tmp_trade._order_profit = StrToDouble(value);
                   break;
                case 11:
                   tmp_trade._order_swap = StrToDouble(value);
                   break;
                case 12:
                   tmp_trade._order_comission = StrToDouble(value);
                   break;
                case 13:
                   tmp_trade._order_opened_time = StrToTime(value);
                   break;
                case 14:
                   tmp_trade._order_closed_time = StrToTime(value);
                   break;
                case 15:
                   tmp_trade._order_expiry = StrToTime(value);
                   break;
                case 16:
                   tmp_trade._magic_number = StrToInteger(value);
                   break;
                case 17:
                   tmp_trade._order_comment = value;
                   break;
                case 18:
                   tmp_trade._trade_entry_tag = value;
                   break;
                case 19:
                   tmp_trade._hedge_trade = StrToBool(value);
                   break;
                case 20:
                   tmp_trade._hedge_assist_trade = StrToBool(value);
                   break;
                case 21:
                   tmp_trade._hedge_internal_trade = StrToBool(value);
                   break;
                case 22:
                   tmp_trade._saved_lot = StrToDouble(value);
                   break;
                case 23:
                   tmp_trade._reverse_source = StrToInteger(value);
                   break;
                case 24:
                   tmp_trade._reverse_count = StrToInteger(value);
                   break;
                case 25:
                   tmp_trade._recover_mother = StrToBool(value);
                   break;  
                case 26:
                   tmp_trade._recover_source = StrToInteger(value);
                   break;
                case 27:
                   tmp_trade._recover_count = StrToInteger(value);
                   break;
                case 28:
                   tmp_trade._recover_be_price = StrToDouble(value);
                   break;
                case 29:
                   tmp_trade._recover_trail_start = StrToBool(value);
                   break;
                case 30:
                   tmp_trade._reverse_jie_source = StrToInteger(value);
                   break;
                case 31:
                   tmp_trade._reverse_jie_count = StrToInteger(value);
                   break;
                case 32:
                   tmp_trade._reverse_jie_in_loss = StrToBool(value);
                   break;
                case 33:
                   tmp_trade._roulette_source = StrToInteger(value);
                   break;
                case 34:
                   tmp_trade._roulette_count = StrToInteger(value);
                   break;
                case 35:
                   tmp_trade._roulette_in_win = StrToBool(value);
                   break;
                case 36:
                   tmp_trade._grid_tag = StrToDouble(value);
                   break;
                case 37:
                   tmp_trade._grid_count = StrToInteger(value);
                   break;
                case 38:
                   tmp_trade._grid_distance = StrToDouble(value);
                   break;
                case 39:
                   tmp_trade._grid_base_lot = StrToDouble(value);
                   break;
                case 40:
                   tmp_trade._grid_multiplier = StrToDouble(value);
                   break;
                case 41:
                   tmp_trade._grid_sl_pip = StrToDouble(value);
                   break;
                case 42:
                   tmp_trade._grid_tp_pip = StrToDouble(value);
                   break;
                case 43:
                   tmp_trade._angry_martin_source = StrToInteger(value);
                   break;
                case 44:
                   tmp_trade._angry_martin_count = StrToInteger(value);
                   break;
                case 45:
                   tmp_trade._angry_martin_distance = StrToInteger(value);
                   break;
                case 46:
                   tmp_trade._yoav_source = StrToInteger(value);
                   break;
                case 47:
                   tmp_trade._yoav_count = StrToInteger(value);
                   break;
                case 48:
                   tmp_trade._yoav_base_lot = StrToDouble(value);
                   break;
                case 49:
                   tmp_trade._yoav_latest_tp = StrToDouble(value);
                   break;
                case 50:
                   tmp_trade._breakeven_tag = StrToBool(value);
                   break;
                case 51:
                   tmp_trade._trailed_tag = StrToBool(value);
                   break;
                
            }
            if(FileIsLineEnding(read_handle))
            {
                //Alert("Prepare to add trade");
                if(
                    !DuplicateTradeCheck(tmp_trade._ticket_number,trades) &&  //check not duplicate trades
                    tmp_trade._order_symbol == symbol                         //check correct symbol
                  ) 
                {
                      //Alert("Adding trade of status ",tmp_trade._active);
                      int size = ArraySize(trades);
                      ArrayResize(trades,size+1);
                      trades[size] = tmp_trade;
                }
                row++;
                //reset temp settings
                col = 0;
                TRADE_LIST empty_trade;
                tmp_trade = empty_trade;  
            }
            else
            {
                col++;
            }
        } 
        FileClose(read_handle);
   }
}

bool clsConfig::DuplicateTradeCheck(int ticket, TRADE_LIST &trades[])
{
   for(int i = 0; i < ArraySize(trades); i++)
   {
       if(trades[i]._ticket_number == ticket)
       {
           return(true);
       }
   }
   return(false);
}

void clsConfig::WriteTradeList(string symbol, TRADE_LIST &trades[])
{
   if(INDI.blNewBar())
   {
      string file_name = symbol+"_TRADES.csv";
      string to_write;
      for(int i = 0; i < ArraySize(trades); i++)
      {
            string line_content = BoolToString(trades[i]._active)+";"+
                                  (string)trades[i]._order_type+";"+
                                  (string)trades[i]._ticket_number+";"+
                                  (string)trades[i]._order_symbol+";"+
                                  (string)trades[i]._order_lot+";"+
                                  (string)trades[i]._open_price+";"+
                                  (string)trades[i]._close_price+";"+
                                  (string)trades[i]._entry+";"+
                                  (string)trades[i]._stop_loss+";"+
                                  (string)trades[i]._take_profit+";"+
                                  (string)trades[i]._order_profit+";"+
                                  (string)trades[i]._order_swap+";"+
                                  (string)trades[i]._order_comission+";"+
                                  (string)trades[i]._order_opened_time+";"+
                                  (string)trades[i]._order_closed_time+";"+
                                  (string)trades[i]._order_expiry+";"+
                                  (string)trades[i]._magic_number+";"+
                                  (string)trades[i]._order_comment+";"+
                                  (string)trades[i]._trade_entry_tag+";"+
                                  BoolToString(trades[i]._hedge_trade)+";"+
                                  BoolToString(trades[i]._hedge_assist_trade)+";"+
                                  BoolToString(trades[i]._hedge_internal_trade)+";"+
                                  (string)trades[i]._saved_lot+";"+
                                  BoolToString(trades[i]._recover_mother)+";"+
                                  (string)trades[i]._reverse_source+";"+
                                  (string)trades[i]._reverse_count+";"+
                                  (string)trades[i]._recover_source+";"+
                                  (string)trades[i]._recover_count+";"+
                                  (string)trades[i]._recover_be_price+";"+
                                  BoolToString(trades[i]._recover_trail_start)+";"+
                                  (string)trades[i]._reverse_jie_source+";"+
                                  (string)trades[i]._reverse_jie_count+";"+
                                   BoolToString(trades[i]._reverse_jie_in_loss)+";"+
                                  (string)trades[i]._roulette_source+";"+
                                  (string)trades[i]._roulette_count+";"+
                                  (string)trades[i]._roulette_in_win+";"+
                                  (string)trades[i]._grid_tag+";"+
                                  (string)trades[i]._grid_count+";"+
                                  (string)trades[i]._grid_distance+";"+
                                  (string)trades[i]._grid_base_lot+";"+
                                  (string)trades[i]._grid_multiplier+";"+
                                  (string)trades[i]._grid_sl_pip+";"+
                                  (string)trades[i]._grid_tp_pip+";"+
                                  (string)trades[i]._angry_martin_source+";"+
                                  (string)trades[i]._angry_martin_count+";"+
                                  (string)trades[i]._angry_martin_distance+";"+
                                  (string)trades[i]._angry_martin_base_lot+";"+
                                  (string)trades[i]._yoav_source+";"+
                                  (string)trades[i]._yoav_count+";"+
                                  (string)trades[i]._yoav_base_lot+";"+
                                  (string)trades[i]._yoav_latest_tp+";"+
                                  BoolToString(trades[i]._breakeven_tag)+";"+
                                  BoolToString(trades[i]._trailed_tag)+";"+
                                  "\n";
         to_write += line_content;
      }
      if(FileIsExist(file_name,this.blCommonFlag))
      {
             FileDelete(file_name);
             //handle just use filename
             int handle        = FileOpen(file_name,FILE_READ|FILE_WRITE|FILE_CSV);
             if(handle!=INVALID_HANDLE) 
             {
                FileWriteString(handle,to_write);
                FileClose(handle); 
                Print("Writing");
                //ExpertRemove();
             }
             else
             {
                Print("Wrong handle in writing new file");
                Print("Error code ",GetLastError()); 
             }
      }
      else
      {
             //handle just use filename
             int handle        = FileOpen(file_name,FILE_READ|FILE_WRITE|FILE_CSV);
             if(handle!=INVALID_HANDLE) 
             {
                FileWriteString(handle,to_write);
                FileClose(handle); 
                Print("Writing");
                //ExpertRemove();
             }
             else
             {
                Print("Wrong handle in writing new file");
                Print("Error code ",GetLastError()); 
             }
      }
   }
}

void clsConfig::WriteHedgeData(string file_name, string to_write)
{
      if(FileIsExist(file_name,this.blCommonFlag))
      {
             //Alert("Hedge File Exis");
             FileDelete(file_name,blCommonFlag);
             /*
             if(FileDelete(file_name,blCommonFlag))
             {
                 Alert("Hedge File Deleted");
                 ExpertRemove();
             }
             */
             //handle just use filename
             int handle        = FileOpen(file_name,FILE_READ|FILE_WRITE|FILE_CSV|FILE_SHARE_READ);
             if(handle!=INVALID_HANDLE) 
             {
                FileWriteString(handle,to_write);
                FileClose(handle); 
                //Print("Writing Hedge Data");
                //ExpertRemove();
             }
             else
             {
                Print("Wrong handle in writing new file");
                Print("Error code ",GetLastError()); 
             }
      }
      else
      {
             //handle just use filename
             int handle        = FileOpen(file_name,FILE_READ|FILE_WRITE|FILE_CSV);
             if(handle!=INVALID_HANDLE) 
             {
                FileWriteString(handle,to_write);
                FileClose(handle); 
                Print("Writing Hedge Config");
                //ExpertRemove();
             }
             else
             {
                Print("Wrong handle in writing new hedge config file");
                Print("Error code ",GetLastError()); 
             }
      }
}

void clsConfig::ReadHedgeData(string input_file_name, HEDGE_CONFIG &HEDGE)
{
   string file_name     =  this.strFolderPath()+"\\"+input_file_name;
   if(FileIsExist(input_file_name,this.blCommonFlag))
   {
       Alert("Hedge Config File Present");
      
       int row = 0; int col = 0;
       //we read config
       int read_handle = FileOpen(input_file_name,FILE_READ|FILE_CSV,",");
       //HEDGE_CONFIG temp_indicator;
       while(!FileIsEnding(read_handle))
       { 
          
          string value = FileReadString(read_handle);
          
          switch (col)
          {
              case 0:
                  HEDGE.blHedgeTag        = StrToBool(value);
                  Alert("Case 0 value is ",value);
                  break;
              case 1:
                  HEDGE.blHedgeBreakEven  = StrToBool(value);
                  Alert("Case 1 value is ",value);
                  break;
              case 2:
                  HEDGE.intHedgeInitiator  = (int)StringToInteger(value);
                  Alert("Case 2 value is ",value);
                  break;
          }
          
          if(FileIsLineEnding(read_handle))
          {
             if(row > 1)
             {
                //int cur_size = ArraySize(this.indicators);
                //ArrayResize(this.indicators,cur_size+1);
                //this.indicators[cur_size] = temp_indicator;
                
             }
             //reset temp settings
             //INDICATOR empty_indicator;
             //temp_indicator = empty_indicator;
             row++;
             col = 0;
             
             
          }
          else
          {
             //return;
             col++;
          }
          
          
       }
       FileClose(read_handle);
   }
}

void clsConfig::WriteData(string input_file_name, string header, string data, bool insert_end=true)
{
   //Data File Name need to have extension
   //Data format will be Var_1; Var_2; Var_3; Var_4;
   string file_name     =  this.strFolderPath()+"\\"+input_file_name;
   Print("File name is ",file_name);
   if(FileIsExist(input_file_name,this.blCommonFlag))
   {
       //if file exist
       //handle just use filename
       int handle        = FileOpen(input_file_name,FILE_READ|FILE_WRITE|FILE_CSV);
       if(insert_end) FileSeek(handle,0,SEEK_END);
       string to_write   = data+"\n";
       Print("To write at end is ",to_write);
       if(handle!=INVALID_HANDLE) 
       {
          FileWriteString(handle,to_write);
          FileClose(handle); 
       }
       else
       {
          Print("Wrong handle in continue writing");
          Print("Error code ",GetLastError()); 
       }
   }
   else
   {
       //handle just use filename
       int handle        = FileOpen(input_file_name,FILE_READ|FILE_WRITE|FILE_CSV);
       string column     = header+"\n";
       string first_data = data+"\n";
       string to_write   = column + first_data;
       if(handle!=INVALID_HANDLE) 
       {
          FileWriteString(handle,to_write);
          FileClose(handle); 
       }
       else
       {
          Print("Wrong handle in writing new file");
          Print("Error code ",GetLastError()); 
       }
   }
}

void clsConfig::ReadIndicator(string input_file_name)
{
   ArrayFree(this.indicators);
   string file_name     =  this.strFolderPath()+"\\"+input_file_name;
   if(FileIsExist(input_file_name,this.blCommonFlag))
   {
       Print("Indicator File Present");
      
       int row = 0; int col = 0;
       //we read config
       int read_handle = FileOpen(input_file_name,FILE_READ|FILE_CSV,",");
       INDICATOR temp_indicator;
       while(!FileIsEnding(read_handle))
       { 
          
          string value = FileReadString(read_handle);
          
          switch (col)
          {
              case 0:
                  temp_indicator.date      = StrToTime(value);
                  break;
              case 1:
                  temp_indicator.value     = StrToDouble(value);
                  break;
              
          }
          
          if(FileIsLineEnding(read_handle))
          {
             if(row > 1)
             {
                int cur_size = ArraySize(this.indicators);
                ArrayResize(this.indicators,cur_size+1);
                this.indicators[cur_size] = temp_indicator;
                
             }
             //reset temp settings
             INDICATOR empty_indicator;
             temp_indicator = empty_indicator;
             row++;
             col = 0;
             
             
          }
          else
          {
             col++;
          }
          
       }
   }
   
}

void clsConfig::ReadConfig(void)
{
   //reset the storage first
   ArrayFree(this.config_settings);
   string file     =  this.strFolderPath()+"\\"+this.strConfigFileName;
   //Print("File Name is ",file);
   
   if(FileIsExist(this.strConfigFileName,this.blCommonFlag))
   {
       Print("Config File Present");
       
       int row = 0; int col = 0;
       //we read config
       int read_handle = FileOpen(this.strConfigFileName,FILE_READ|FILE_CSV,",");
       //create a temp setting
       SETTING temp_setting;
       while(!FileIsEnding(read_handle))
       { 
          
          string value = FileReadString(read_handle);
          
          switch (col)
          {
              case 0:
                  temp_setting.Pair          = value;
                  break;
              case 1:
                  temp_setting.Amplitude     = (double)value;
                  break;
              case 2:
                  temp_setting.Fix_Tp        = (double)value;
                  break;
              case 3:
                  temp_setting.RSIPer        = (double)value;
                  break;
              case 4:
                  temp_setting.LotExponent   = (double)value;
                  break;
              case 5:
                  temp_setting.MagicNumber   = (int)value;
                  break;
              case 6:
                  temp_setting.Entry_Percent = (double)value;
                  break;
          }
          
          if(FileIsLineEnding(read_handle))
          {
             if(row > 1)
             {
                int cur_size = ArraySize(this.config_settings);
                ArrayResize(this.config_settings,cur_size+1);
                this.config_settings[cur_size] = temp_setting;
                
             }
             //reset temp settings
             SETTING empty_setting;
             temp_setting = empty_setting;
             row++;
             col = 0;
             
             
          }
          else
          {
             col++;
          }
          
       }
       FileClose(read_handle);
       
   }  
   else
   {
       Print("File Not Exist, Create New");
       int handle =  FileOpen(this.strConfigFileName,FILE_READ|FILE_WRITE|FILE_CSV);
       string header = "sep=,\n";
       string column = "Pair,Amplitude,Fix_Tp,RSIPer,LotExponent,MagicNumber,Entry_Percent\n";
       
       string audcad = "AUDCAD,18, 185,  9, 1.05, 88888, 0.70 \n";
       string audchf = "AUDCHF, 2, 175,  9, 1.05, 55555, 0.70 \n";
       string audjpy = "AUDJPY, 1, 100, 14, 1.10,  8888, 0.45 \n";
       string audnzd = "AUDNZD,24, 270, 14, 1.15,  6666, 0.60 \n";
       string audusd = "AUDUSD, 8, 105,  9, 1.10,   222, 0.75 \n";
       string cadchf = "CADCHF, 1, 160,  9, 1.05, 44444, 0.70 \n";
       string cadjpy = "CADJPY,36, 120, 14, 1.10,   666, 0.65 \n";
       string chfjpy = "CHFJPY,29,  85, 14, 1.20,  7777, 0.45 \n";
       string euraud = "EURAUD,34, 135, 14, 1.10, 11111, 0.50 \n";
       string eurcad = "EURCAD, 1, 185, 14, 1.10, 33333, 0.65 \n";
       string eurchf = "EURCHF,23,  75, 14, 1.05,  9999, 0.30 \n";
       string eurgbp = "EURGBP,16,  75,  9, 1.05,   999, 0.45 \n";
       string eurjpy = "EURJPY,25,  75,  9, 1.05,   111, 0.50 \n";
       string eurnzd = "EURNZD, 8, 285, 14, 1.20,111111, 0.60 \n";
       string eurusd = "EURUSD, 1,  85,  9, 1.15,   777, 0.70 \n";
       string gbpaud = "GBPAUD, 6, 195,  9, 1.05,   444, 0.45 \n";
       string gbpcad = "GBPCAD,15, 205, 14, 1.20,  2222, 0.40 \n";
       string gbpjpy = "GBPJPY, 5, 100,  9, 1.05,  3333, 0.80 \n";
       string gbpusd = "GBPUSD,18,  75,  9, 1.10,   555, 0.80 \n";
       string nzdcad = "NZDCAD, 6, 210,  9, 1.15,  5555, 0.70 \n";
       string nzdjpy = "NZDJPY,13, 135, 14, 1.20, 99999, 0.70 \n";
       string nzdusd = "NZDUSD,33,  75,  9, 1.20,   333, 0.65 \n";
       string usdcad = "USDCAD,13,  85, 14, 1.10,   888, 0.25 \n";
       string usdchf = "USDCHF, 1,  75,  9, 1.15,  1111, 0.80 \n";
       string usdjpy = "USDJPY, 1,  75,  9, 1.15,  4444, 0.50 \n";
       string usdnok = "USDNOK, 5, 850, 14, 1.05, 77777, 0.45 \n";
       string usdsek = "USDSEK, 6, 850,  9, 1.20, 66666, 0.70 \n";
       
       string output =  header + column + audcad + audchf + audjpy + audnzd + audusd + cadchf + cadjpy + chfjpy + euraud + eurcad + eurchf + eurgbp +
                        eurjpy + eurnzd + eurusd + gbpaud + gbpcad + gbpjpy + gbpusd + nzdcad + nzdjpy + nzdusd + usdcad + usdchf + usdjpy + usdnok+ usdsek;
       FileWriteString(handle,output);
       FileClose(handle); 
   }
}