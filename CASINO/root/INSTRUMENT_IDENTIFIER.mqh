extern string EXP      = "=== SYMBOL IDENTIFIER : ADD WITH COMMA TO SEPERATE ===";
extern string GOLD     = "XAUUSD,GOLD"; //GOLD
extern string SILVER   = "XAGUSD,SILVER"; //SILVER
extern string OIL      = "Oil,USOil,UKOil,WTI"; //ENERGY
extern string INDICES  = "GER30,US500,US30,US100,UK100,AUS200,U50,FRA40,HK50,JP225,SPN35,VIX"; //INDICES
extern string FUTURES  = "USTN,DX,ERBN,NATGAS"; // FUTURE
//string INDICES  = "NAS100,SPX500,US30,GER30,FRA40,JPN225,AUS200,ESP35,EUSTX50,US30.cash";//INDICES
//string EQUITIES = 
extern string MT4_METAL_POSTFIX   = "";
extern string MT4_OIL_POSTFIX     = ".cash"; 
extern string MT4_INDICES_POSTFIX = ".cash";
extern string MT4_FUTURES_POSTFIX = ".f";
class clsInstrumentType
{
      public:
         void clsInstrumentType(string strInputSymbol);
         void ~clsInstrumentType();
         void Oninit();
         int    intType; //TYPE 1 : FOREX; TYPE 2 : METAL/ENERGY; TYPE 3 : INDICES
         string strFinalName;
         int    intMultipleOfTen;
         bool   isGold;
         bool   isSilver;
         bool   isOil;
         bool   isIndices;
         bool   isFutures;
         bool   isOthers;
      protected:
         int    SplitStringToArray(string long_string, string &string_arr[]);
      private:
         string GOLD_LIST[];
         string SILVER_LIST[];
         string OIL_LIST[];
         string INDICES_LIST[];
         string FUTURE_LIST[];
         string strCurrSymbol;
         int    intGoldSize;
         int    intSilverSize;
         int    intOilSize;
         int    intIndicesSize;
         int    intFutureSize;
         void   FindType();
         void   GetFinalName();
         void   GetMultipleOfTen();
};

void clsInstrumentType::clsInstrumentType(string strInputSymbol)
{
    this.strCurrSymbol = strInputSymbol;
    this.Oninit();
}

void clsInstrumentType::~clsInstrumentType(){}

void clsInstrumentType::Oninit(void)
{
    this.intType = 1; //we initialize all as Fx pair first
    this.intGoldSize    = this.SplitStringToArray(GOLD,this.GOLD_LIST);
    this.intSilverSize  = this.SplitStringToArray(SILVER,this.SILVER_LIST);
    this.intOilSize     = this.SplitStringToArray(OIL,this.OIL_LIST);
    this.intIndicesSize = this.SplitStringToArray(INDICES,this.INDICES_LIST);
    this.intFutureSize  = this.SplitStringToArray(FUTURES,this.FUTURE_LIST);
    this.FindType();
    this.GetFinalName();
    this.GetMultipleOfTen();
}

int clsInstrumentType::SplitStringToArray(string long_string, string &string_arr[])
{
    string sep=",";
    ushort u_sep; 
    u_sep=StringGetCharacter(sep,0);
    int size=StringSplit(long_string,u_sep,string_arr);
    return (size);
}

void clsInstrumentType::FindType(void)
{
    //CHANGE TO UPPER CASE FIRST
    string upper_symbol = this.strCurrSymbol;
    StringToUpper(upper_symbol);
    string keyword = "";
    for(int i = 0; i < intGoldSize; i++)
    {
         //change keyword to capitl
         keyword = this.GOLD_LIST[i];
         StringToUpper(keyword);
         if(StringFind(upper_symbol,keyword,0) >= 0 &&
            StringFind(upper_symbol,keyword,0) < 3
           )
         {
             //Alert("Check Symbol is ",this.strCurrSymbol," with position of ",StringFind(this.strCurrSymbol,keyword,0));
             this.intType = 2; //METAL
             this.isGold = true;
             return;
         }
   }
   
   for(int i = 0; i < intSilverSize; i++)
   {
         //change keyword to capitl
         keyword = this.SILVER_LIST[i];
         StringToUpper(keyword);
         if(StringFind(upper_symbol,keyword,0) >= 0 &&
            StringFind(upper_symbol,keyword,0) < 3
           )
         {
             this.intType = 2; //METAL
             this.isSilver = true;
             return;
         }
   }
   
   for(int i = 0; i < intOilSize; i++)
   {
         //change keyword to capitl
         keyword = this.OIL_LIST[i];
         StringToUpper(keyword);
         if(StringFind(upper_symbol,keyword,0) >= 0 &&
            StringFind(upper_symbol,keyword,0) < 3
          )
         {
             this.intType = 3; //ENERGY
             this.isOil = true;
             return;
         }
   }
   
   for(int i = 0; i < intIndicesSize; i++)
   {
         //change keyword to capitl
         keyword = this.INDICES_LIST[i];
         StringToUpper(keyword);
         if(StringFind(upper_symbol,keyword,0) >= 0)
         {
             this.intType = 4; //INDICES
             this.isIndices = true;
             return;
         }
   }
   
   for(int i = 0; i < intFutureSize; i++)
   {
         //change keyword to capitl
         keyword = this.FUTURE_LIST[i];
         StringToUpper(keyword);
         if(StringFind(upper_symbol,keyword,0) >= 0)
         {
             this.intType = 5; //FUTURES
             this.isFutures = true;
             return;
         }
   }
   //the rest is either forex or others
   if(MarketInfo(this.strCurrSymbol,MODE_LOTSIZE)!=100000)
   {
      this.intType = 6; //OTHERS
      this.isOthers = true;
      return;   
   }
  
   if(this.intType == 1)
   {
      this.isGold    = False;
      this.isSilver  = False;
      this.isOil     = False;
      this.isIndices = False;
      this.isFutures = False;
      this.isOthers  = False;
   }
   
}

void clsInstrumentType::GetFinalName(void)
{
   switch(this.intType)
   {
         case 2:
              this.strFinalName = this.strCurrSymbol + MT4_METAL_POSTFIX;
              break;
         case 3:
              this.strFinalName = this.strCurrSymbol + MT4_OIL_POSTFIX;
              break;
         case 4:
              this.strFinalName = this.strCurrSymbol + MT4_INDICES_POSTFIX;
              break;     
         case 5:
              this.strFinalName = this.strCurrSymbol + MT4_FUTURES_POSTFIX;
              break;
         default:
              this.strFinalName = this.strCurrSymbol; // default remain intact   
   }
}


void clsInstrumentType::GetMultipleOfTen(void)
{   
   double bid = MarketInfo(this.strFinalName,MODE_BID);
   //Alert("Bid in identifier is ",bid);
   for(int i = 1; i < 10; i++)
   {
        double divisor = MathPow(10,i);
        if( (bid/divisor) >= 0 && (bid/divisor) < 10)
        {
             this.intMultipleOfTen = i;
             break;
        }
   }
}
