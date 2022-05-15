//#include "/01bot.mqh"
#include "/01bot.mqh"
#include "/CUSTOM_BAR.mqh"
//#include "/CIRCLE.mqh"
//#define INVERT_TRADE
clsConfig *READ_WRITE;
clsCustomBar *CUSTOM;
//CCircleSimple ind1;
class clsCoordinator
{
    public:
      clsCoordinator();
      ~clsCoordinator();
      void Oninit();
      void Updater();
      void ProcessTrade();
      clsBot01 *Bot[]; //switch robot by type here
    protected:
    
    private:
      void OpenTrade(SIGNAL_LIST &BUY_LIST[], SIGNAL_LIST &SELL_LIST[]);
      void UpdateBot();
      
      string strSymbols[];
      double dblBuyMargin(SIGNAL_LIST &BUY_SIGNALS[]);
      double dblSellMargin(SIGNAL_LIST &SELL_SIGNALS[]);
};

clsCoordinator::clsCoordinator(void)
{
   //Print("Prepare Coordinator Oninit");
   
   this.Oninit();
   
   //READ WRITE
   READ_WRITE = new clsConfig();
   READ_WRITE.ReadTradeList(ChartSymbol(),TRADE._terminal_trades);
   
}

clsCoordinator::~clsCoordinator(void)
{
    for(int i = 0; i < ArraySize(this.strSymbols); i++)
    {
       if(CheckPointer(this.Bot[i])==POINTER_DYNAMIC) delete this.Bot[i];
    }
    if(CheckPointer(MM)==POINTER_DYNAMIC) delete MM;
    if(CheckPointer(TRADE)==POINTER_DYNAMIC) delete TRADE;
    if(CheckPointer(READ_WRITE) == POINTER_DYNAMIC) delete READ_WRITE;
    if(CheckPointer(CUSTOM) == POINTER_DYNAMIC) delete CUSTOM;
}

void clsCoordinator::Oninit(void)
{
    #ifdef MULTISYMBOL_TRADE
      ArrayCopy(this.strSymbols,symbol_list);
    #else
      ArrayResize(this.strSymbols,1);
      this.strSymbols[0] = ChartSymbol();
    #endif
    MM = new clsMoneyManagement();
    TRADE = new clsTradeClass();
    ArrayResize(this.Bot,ArraySize(symbol_list));
    for(int i = 0; i < ArraySize(this.strSymbols); i++)
    {
          //Print("Creating Signal Bot for ",this.strSymbols[i]);
          this.Bot[i] =  new clsBot01(this.strSymbols[i]);
    }
    
    //Print("Initial Trade in List is ",ArraySize(TRADE._terminal_trades));
}

void clsCoordinator::UpdateBot(void)
{
    for(int i = 0; i < ArraySize(this.strSymbols); i++)
    {
          this.Bot[i].Updater();
    }
}

void clsCoordinator::Updater(void)
{
    MM.Updater();
    TRADE.Updater();
    this.UpdateBot();
    //write the file
    if(!IsTesting()) READ_WRITE.WriteTradeList(ChartSymbol(),TRADE._terminal_trades);
}

void clsCoordinator::ProcessTrade(void)
{
    SIGNAL_LIST BUY_LIST[];
    SIGNAL_LIST SELL_LIST[];
    for(int i = 0; i < ArraySize(this.strSymbols); i++)
    {
         SIGNAL_LIST signal;
         if(this.Bot[i].blBuyLogic(signal))
         {
               //Print("Dividing Buy Symbol ",signal._symbol);
               signal._sl_pip = (signal._entry - signal._sl)/pips(signal._symbol);
               int buy_size = ArraySize(BUY_LIST);
               ArrayResize(BUY_LIST,buy_size+1);
               BUY_LIST[buy_size] = signal;
         }
         
         if(this.Bot[i].blSellLogic(signal))
         {
               //Print("Dividing Sell Symbol ",signal._symbol);
               signal._sl_pip = (signal._sl - signal._entry)/pips(signal._symbol);
               int sell_size = ArraySize(SELL_LIST);
               ArrayResize(SELL_LIST,sell_size+1);
               SELL_LIST[sell_size] = signal;
         }
    }
    this.OpenTrade(BUY_LIST,SELL_LIST);
}

double clsCoordinator::dblBuyMargin(SIGNAL_LIST &BUY_SIGNALS[])
{
   return(MM.dblMarginRequired(BUY_SIGNALS));
}

double clsCoordinator::dblSellMargin(SIGNAL_LIST &SELL_SIGNALS[])
{
   return(MM.dblMarginRequired(SELL_SIGNALS));
}

void clsCoordinator::OpenTrade(SIGNAL_LIST &BUY_LIST[], SIGNAL_LIST &SELL_LIST[])
{
    int    buy_size  = ArraySize(BUY_LIST);
    int    sell_size = ArraySize(SELL_LIST);
    //int    total_trade_to_open = buy_size + sell_size;
    //double total_margin =  this.dblSellMargin(SELL_LIST) + this.dblBuyMargin(BUY_LIST); 
    //double free_margin = MM.dblAccountFreeMargin;
    
    //Print("Free Margin is ",free_margin);
    //Print("Total Margin is ",total_margin);
    //if(free_margin > total_margin &&
    //   total_margin != 0 
    //  )
    //{
         //int factor = (int)(free_margin/total_margin);
         if(buy_size > 0)
         {
             
             for(int i = 0; i < ArraySize(BUY_LIST); i++)
             {    
                  
                  TRADE.TradeLimitReset();   //RESET ON EACH LOOP
                  #ifdef ALLOW_SCALE
                    TRADE.intMaxBuy = factor;
                  #endif 
                  #ifdef INVERT_TRADE
                     TRADE_COMMAND new_sell_trade;
                     new_sell_trade._action = MODE_TOPEN;  //a tag to indicate open new trade
                     new_sell_trade._order_type = 1; //buy action, as we already configure in trading script for Market, Limit, Stop Order
                     new_sell_trade._symbol = BUY_LIST[i]._symbol;
                     double spread = MarketInfo(BUY_LIST[i]._symbol,MODE_ASK) - MarketInfo(BUY_LIST[i]._symbol,MODE_BID);
                     new_sell_trade._entry  = BUY_LIST[i]._entry - spread;
                     new_sell_trade._sl     = BUY_LIST[i]._tp;
                     new_sell_trade._tp     = BUY_LIST[i]._sl;
                     new_sell_trade._lots   = BUY_LIST[i]._lot;
                     new_sell_trade._saved_lot = BUY_LIST[i]._lot;
                     new_sell_trade._comment = "REVERSE SELL";
                     //Print("Lot is ",BUY_LIST[i]._lot);
                     new_sell_trade._magic  = BUY_LIST[i]._magic;
                     TRADE.EnterTrade(new_sell_trade);
                     return;
                  #endif 
                  TRADE_COMMAND new_buy_trade;
                  new_buy_trade._action = MODE_TOPEN;  //a tag to indicate open new trade
                  new_buy_trade._order_type = 0; //buy action, as we already configure in trading script for Market, Limit, Stop Order
                  new_buy_trade._symbol = BUY_LIST[i]._symbol;
                  new_buy_trade._entry  = BUY_LIST[i]._entry;
                  new_buy_trade._sl     = BUY_LIST[i]._sl;
                  new_buy_trade._tp     = BUY_LIST[i]._tp;
                  new_buy_trade._lots   = BUY_LIST[i]._lot;
                  new_buy_trade._saved_lot   = BUY_LIST[i]._lot;
                  //Print("Lot is ",BUY_LIST[i]._lot);
                  new_buy_trade._magic  = BUY_LIST[i]._magic;
                  
                  //Alert("Come inside frequency is ",count);
                  TRADE.EnterTrade(new_buy_trade);
             }
         }
        if(sell_size > 0)
         {
             for(int j = 0; j < ArraySize(SELL_LIST); j++)
             {
                  TRADE.TradeLimitReset();
                  #ifdef ALLOW_SCALE
                     TRADE.intMaxSell = factor;
                  #endif 
                  #ifdef INVERT_TRADE
                        TRADE_COMMAND new_buy_trade;
                        new_buy_trade._action = MODE_TOPEN;  //a tag to indicate open new trade
                        new_buy_trade._order_type = 0; //sell action, as we already configure in trading script for Market, Limit, Stop Order
                        new_buy_trade._symbol = SELL_LIST[j]._symbol;
                        double spread = MarketInfo(SELL_LIST[j]._symbol,MODE_ASK) - MarketInfo(SELL_LIST[j]._symbol,MODE_BID);
                        new_buy_trade._entry  = SELL_LIST[j]._entry + spread;
                        new_buy_trade._sl     = SELL_LIST[j]._tp;
                        new_buy_trade._tp     = SELL_LIST[j]._sl;
                        new_buy_trade._lots   = SELL_LIST[j]._lot;
                        new_buy_trade._saved_lot = SELL_LIST[j]._lot;
                        new_buy_trade._magic  = SELL_LIST[j]._magic;
                        new_buy_trade._comment = "REVERSE BUY";
                        TRADE.EnterTrade(new_buy_trade);
                        return;
                  #endif 
                  TRADE_COMMAND new_sell_trade;
                  new_sell_trade._action = MODE_TOPEN;  //a tag to indicate open new trade
                  new_sell_trade._order_type = 1; //sell action, as we already configure in trading script for Market, Limit, Stop Order
                  new_sell_trade._symbol = SELL_LIST[j]._symbol;
                  new_sell_trade._entry  = SELL_LIST[j]._entry;
                  new_sell_trade._sl     = SELL_LIST[j]._sl;
                  new_sell_trade._tp     = SELL_LIST[j]._tp;
                  new_sell_trade._lots   = SELL_LIST[j]._lot;
                  new_sell_trade._saved_lot   = SELL_LIST[j]._lot;
                  new_sell_trade._magic  = SELL_LIST[j]._magic;
                  TRADE.EnterTrade(new_sell_trade);
             }
         }
       
       
       
    //}
}