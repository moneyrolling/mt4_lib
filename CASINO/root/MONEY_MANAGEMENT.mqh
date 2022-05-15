//+--------------------------------------------------------------------------------+
//| Changelog : 
//    24/2/2022 : Fix PseudoEquity Calculation Error             
//                Addon back the old PESUDO MM File                                               
//                To re-sequence back with MASTER_BOT.mqh and MONEY_MANAGEMENT.mqh
//                Add back Kelly Lot and Lot 2k
//+--------------------------------------------------------------------------------+


#include "TRADING_NEW.mqh"
#include "INSTRUMENT_IDENTIFIER.mqh"

enum   LOT_MODE  
{
    FIX_LOT_MODE  = 1,
    MONEY_MODE    = 2,
    RISK_LOT_MODE = 3,
    KELLY_LOT_MODE = 4,
    CMPD_2K_LOT_MODE = 5
};
extern string _tmp1_ = "===== LOT SIZE=====";
extern LOT_MODE Lot_Mode = 1;
extern double fix_lot_size = 0.01;
extern double LotSizePer2000 = 0.02; 
extern double money_size = 100;
extern double risk_percent = 1;  //how many percent to risk per trade
double safe_margin_factor = 0.8; //save factor to prevent margin drain
extern string _tmp_pseudo_margin_ = "===== PSEUDOMARGIN SETTING =====";
extern bool   Use_Pseudo_Margin = true;
extern double pseudo_equity = 10000;
extern double pseudo_stopout_level = 30; //percentage


//string symbol_list[1] = {0};


string symbol_list[27] =
  { 
     "AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD",
     "CADCHF","CADJPY","CHFJPY",
     "EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD","EURUSD",
     "GBPAUD","GBPCAD","GBPCHF","GBPNZD","GBPUSD",
     "NZDCAD","NZDCHF","NZDJPY","NZDUSD",
     "USDCAD","USDCHF","USDJPY"
  };

struct SIGNAL_LIST
{
    string _symbol;
    double _sl_pip;  //this is for processing of margin calculation, do a manual calculation before inserting
    double _entry;
    double _sl;
    double _tp;
    double _lot;
    int    _magic;
    bool   _special_mode;
    TRADE_COMMAND _trade;
    SIGNAL_LIST() : _symbol(""),_sl_pip(0),_entry(0),_sl(0),_tp(0),_lot(0),_magic(0),_special_mode(0){};
};

class clsMoneyManagement 
{
    public:
         clsMoneyManagement(bool pseudo_mode=false);
         ~clsMoneyManagement();
         void Updater();
         double dblAccountFreeMargin;
         double dblLotSizePerRisk(string strInputSymbol, double dblSLPip, int type=1);
         double dblLotSizePerMoney (double dblInputMoney, string strInputSymbol, double dblSLPip);
         int    intSlPipPerPerMoney(double dblInputMoney, string strInputSymbol, double &dblLot); 
         double dblMarginRequired(SIGNAL_LIST &signal[]);
         double dblPipValuePerLot(string strInputSymbol);
         int    intSymbolType(string strInputSymbol);
         double dblContractSize(string strInputSymbol);
         double dblIndMarginRequired(string strInputSymbol, double dblInputLot);
         bool   blPseudoMarginInsufficient(string strInputSymbol);
         bool   blPseudoMarginStoppedOut(string strInputSymbol);
         bool   blPseudoEquityCut(double dblInpPercent);
         double dblPseudoAccountBalance(string strInputSymbol);
         double dblMarginToBase(string margin_cur, string base_cur, double margin_cur_value);
         double dblPseudoStartingEquity;
         double dblPseudoEquity;
         double dblMaxPseudoEquity;
         double dblMaxPseudoDD;
         double dblKellyLot(string strInputSymbol, int intMagic, double dblSlPip, int type=1);
         double dblLot2k(string strInputSymbol);
    protected:
         void Oninit();
    private:
         double dblAccountBalance;
         double dblAccountEquity;
         double dblAccountLeverage;
         string strBaseCurrency;
         double dblRiskPercent;
         string strFindSameBaseHomeQuote(string strInputSymbol);//use for type 3 // aim is to find the same base (for cross pair) where Base Currency Is Quote
         string strFindOppositeHomeQuote(string strInputSymbol);//use for type 4
         
         double dblTotalMarginUsed(string strInputSymbol, double lots_opened);
         int    intMultipleOfTen(double value);
         clsTradeClass      *REF_TRADE;
         
         
};



clsMoneyManagement::clsMoneyManagement(bool pseudo_mode=false)
{
   if(pseudo_mode){ REF_TRADE = PSEUDO_TRADE; }
   else           { REF_TRADE = TRADE; }     
   this.Oninit();
}

clsMoneyManagement::~clsMoneyManagement(void)
{}

void clsMoneyManagement::Oninit(void)
{
   this.dblAccountBalance  = AccountBalance();
   this.dblAccountEquity   = AccountEquity();
   this.dblAccountFreeMargin = AccountFreeMargin()*safe_margin_factor;;
   this.dblAccountLeverage = AccountLeverage();
   this.strBaseCurrency   = "USD";
   this.dblRiskPercent    = risk_percent;
}

void clsMoneyManagement::Updater(void)
{
   this.dblAccountBalance  = AccountBalance();
   this.dblAccountEquity   = AccountEquity();
   this.dblAccountFreeMargin   = AccountFreeMargin()*safe_margin_factor;
}

double clsMoneyManagement::dblTotalMarginUsed(string strInputSymbol, double lots_opened)
{
    //1st : Get margin used by 1 lot
    double margin_per_lot = MarketInfo(strInputSymbol,MODE_MARGINREQUIRED);
    double value          = margin_per_lot * lots_opened;
    return(value);
}

bool clsMoneyManagement::blPseudoMarginInsufficient(string strInputSymbol)
{
    if(Use_Pseudo_Margin)
    {
       TRADE.Updater();
       double opened_lots   = 0;
       double cum_profit    = 0;
       //1. Get total Lots Opened
       for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
       {
           if(REF_TRADE._terminal_trades[i]._order_symbol == strInputSymbol)
           {  
                 cum_profit += REF_TRADE._terminal_trades[i]._order_profit + REF_TRADE._terminal_trades[i]._order_swap + TRADE._terminal_trades[i]._order_comission;
                 if(REF_TRADE._terminal_trades[i]._active)
                 {
                     opened_lots   += REF_TRADE._terminal_trades[i]._order_lot;
                 }
           }
       }
       double total_equity = pseudo_equity + cum_profit;
       double total_margin_used = this.dblTotalMarginUsed(strInputSymbol,opened_lots);
       double margin_level = total_margin_used > 0 ? total_equity/total_margin_used : total_equity;
       if(margin_level * 100 <= 100) {return(true);}
       return(false);
   }
   return(false);
}

double clsMoneyManagement::dblPseudoAccountBalance(string strInputSymbol)
{
    double balance = 0;
    if(CheckPointer(REF_TRADE) != POINTER_DYNAMIC) return(balance);
    REF_TRADE.Updater();
    double cum_profit    = 0;
    for(int i = 0; i < ArraySize(REF_TRADE._historical_trades);i++)
    //for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
        if(REF_TRADE._historical_trades[i]._order_symbol == strInputSymbol)
        {  
              cum_profit += REF_TRADE._historical_trades[i]._order_profit + REF_TRADE._historical_trades[i]._order_swap + REF_TRADE._historical_trades[i]._order_comission;
        }
    }
    balance = pseudo_equity + cum_profit;
    return(balance);
}
bool clsMoneyManagement::blPseudoEquityCut(double dblInpPercent)
{
    double ratio = 1 - (dblInpPercent / 100);
    if(Use_Pseudo_Margin)
    {
        if(dblMaxPseudoEquity != 0 && dblPseudoEquity != 0)
        {
             if(dblPseudoEquity < dblMaxPseudoEquity * ratio)
             {
                 dblMaxPseudoEquity      = dblPseudoEquity;
                 Print("Latest Starting Equity is ",dblMaxPseudoEquity);
                 //ExpertRemove();
                 return(true);
             }
        }
    }
    return(false);
}

bool clsMoneyManagement::blPseudoMarginStoppedOut(string strInputSymbol)
{
    if(Use_Pseudo_Margin)
    {
       TRADE.Updater();
       double opened_lots   = 0;
       double lossed_lots   = 0;
       double cum_profit    = 0;
       double active_profit = 0;
       //1. Get total Lots Opened
       for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
       {
           if(TRADE._terminal_trades[i]._order_symbol == strInputSymbol)
           {  
                 if(TRADE._terminal_trades[i]._active)
                 {
                     opened_lots   += TRADE._terminal_trades[i]._order_lot;
                     double cur_profit = TRADE._terminal_trades[i]._order_profit + TRADE._terminal_trades[i]._order_swap + TRADE._terminal_trades[i]._order_comission;
                     active_profit += cur_profit; //TRADE._terminal_trades[i]._order_profit + TRADE._terminal_trades[i]._order_swap + TRADE._terminal_trades[i]._order_comission;
                     if(active_profit < 0)
                     {
                         lossed_lots += TRADE._terminal_trades[i]._order_lot;
                     } 
                 }
                 else
                 {
                     cum_profit += TRADE._terminal_trades[i]._order_profit + TRADE._terminal_trades[i]._order_swap + TRADE._terminal_trades[i]._order_comission;
                 }
           }
       }
       dblPseudoEquity = pseudo_equity + cum_profit + active_profit;
       
       Print("Cum Profit is ",cum_profit);
       Print("Active Profit is ",active_profit);
       //dblPseudoEquity = dblPseudoEquity + active_profit;
       //dblPseudoEquity = dblPseudoEquity == 0 ? pseudo_equity + active_profit : dblPseudoEquity + active_profit;
       //dblPseudoStartingEquity = dblPseudoStartingEquity == 0 ? pseudo_equity : dblPseudoStartingEquity;
       //JUST FOR CALCULATIONS
       double total_equity = dblPseudoEquity;
       double total_margin_used = this.dblTotalMarginUsed(strInputSymbol,lossed_lots);
       double margin_level = total_margin_used > 0 ? total_equity/total_margin_used : total_equity;
       //dblPseudoEquity = total_equity;
       dblMaxPseudoEquity = MathMax(dblPseudoEquity,dblMaxPseudoEquity);
       double ind_dd = dblMaxPseudoEquity - dblPseudoEquity;
       dblMaxPseudoDD = MathMax(dblMaxPseudoDD,ind_dd);
       Print("Active Profit is : ",active_profit);
       Print("Total Equity is : ",total_equity);
       Print("Margin Level is : ",margin_level);
       //if(total_equity > 11000) ExpertRemove();
       
       //if(dblPseudoEquity > dblMaxPseudoEquity) dblMaxPseudoEquity = dblPseudoEquity;
       if(margin_level * 100 <= pseudo_stopout_level) {return(true);}
       return(false);
   }
   return(false);
}

double clsMoneyManagement::dblLot2k(string strInputSymbol)
{
    double lot_value = fix_lot_size;
    if(LotSizePer2000>0) {
       lot_value = MathMax(NormalizeDouble((int)(dblAccountBalance/2000)*LotSizePer2000,2),0.01);
       if(Use_Pseudo_Margin)
       {
         lot_value = MathMax(NormalizeDouble((int)(dblPseudoAccountBalance(strInputSymbol)/2000)*LotSizePer2000,2),0.01);
       }
    }
    else
    {
         lot_value = fix_lot_size;
    }
    return(lot_value);
}

double clsMoneyManagement::dblKellyLot(string strInputSymbol, int intMagic, double dblSlPip, int type=1)
{
    //get winning probability
    int    total_trades = 0;
    int    win_trades = 0;
    int    loss_trades = 0;
    double sum_win_amount = 0;
    double sum_loss_amount = 0;
    for(int i = 0; i < ArraySize(TRADE._historical_trades); i++)
    {
        if(
            TRADE._historical_trades[i]._magic_number == intMagic &&
            TRADE._historical_trades[i]._order_symbol == strInputSymbol
          )
        {
              total_trades++;
              if(TRADE._historical_trades[i]._order_profit >= 0)
              {
                   win_trades++;
                   sum_win_amount += TRADE._historical_trades[i]._order_profit;
              }
              else
              {
                   loss_trades++;
                   sum_loss_amount += TRADE._historical_trades[i]._order_profit;
              }
        }
    }
    if(total_trades < 10)
    {   
        //we use default risk set
        return(dblLotSizePerRisk(strInputSymbol,dblSlPip,type));
    }
    double w = win_trades/total_trades;
    double average_win  = sum_win_amount/total_trades;
    double average_loss = sum_loss_amount/total_trades;
    double r = average_win/average_loss;
    double risk_taken = w - ((1-w)/r);
    
    double lot_value = this.dblPipValuePerLot(strInputSymbol);
    double ref_balance = type==1 ? this.dblAccountBalance : this.dblAccountEquity;
    if(Use_Pseudo_Margin)
    {
       ref_balance = type==1 ? dblPseudoAccountBalance(strInputSymbol) : dblPseudoEquity;
    }
    double money_to_risk = risk_taken / 100 * ref_balance;
    double risk_1_pip    = money_to_risk /dblSlPip;
    double final_lot     = risk_1_pip/lot_value;
    return(MathMax(final_lot,0.01)); // this is to keep min lot always greater or equal to 0.01
    //return(lot);
}
/*
bool clsMoneyManagement::blPseudoEquityCut(double dblInpPercent)
{
    double ratio = 1 - (dblInpPercent / 100);
    if(Use_Pseudo_Margin)
    {
        if(dblMaxPseudoEquity != 0 && dblPseudoEquity != 0)
        {
             if(dblPseudoEquity < dblMaxPseudoEquity * ratio)
             {
                 dblPseudoStartingEquity = dblPseudoEquity;
                 dblMaxPseudoEquity      = dblPseudoStartingEquity;
                 Print("Latest Starting Equity is ",dblPseudoStartingEquity);
                 return(true);
             }
        }
    }
    return(false);
}

bool clsMoneyManagement::blPseudoMarginStoppedOut(string strInputSymbol)
{
    if(Use_Pseudo_Margin)
    {
       TRADE.Updater();
       double opened_lots   = 0;
       double cum_profit    = 0;
       double active_profit = 0;
       //1. Get total Lots Opened
       for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
       {
           if(TRADE._terminal_trades[i]._order_symbol == strInputSymbol)
           {  
                 cum_profit += TRADE._terminal_trades[i]._order_profit + TRADE._terminal_trades[i]._order_swap + TRADE._terminal_trades[i]._order_comission;
                 if(TRADE._terminal_trades[i]._active)
                 {
                     opened_lots   += TRADE._terminal_trades[i]._order_lot;
                     active_profit += TRADE._terminal_trades[i]._order_profit + TRADE._terminal_trades[i]._order_swap + TRADE._terminal_trades[i]._order_comission;
                 }
           }
       }
       double total_equity = pseudo_equity + cum_profit;
       dblPseudoStartingEquity = dblPseudoStartingEquity == 0 ? pseudo_equity : dblPseudoStartingEquity;
       double total_margin_used = this.dblTotalMarginUsed(strInputSymbol,opened_lots);
       double margin_level = total_margin_used > 0 ? total_equity/total_margin_used : total_equity;
       dblPseudoEquity = dblPseudoStartingEquity + active_profit;
       if(dblPseudoEquity > dblMaxPseudoEquity) dblMaxPseudoEquity = dblPseudoEquity;
       if(margin_level * 100 <= pseudo_stopout_level) {return(true);}
       return(false);
   }
   return(false);
}
*/

double clsMoneyManagement::dblContractSize(string strInputSymbol)
{
    return(MarketInfo(strInputSymbol, MODE_LOTSIZE));
}


int clsMoneyManagement::intSymbolType(string strInputSymbol)
{
    clsInstrumentType INST_TYPE(strInputSymbol);
    int FinalType = 0;
    if(INST_TYPE.intType == 1)
    {
       //GROUP A
       //WE CAN DIVIDE INTO 4 TYPES
       //Scenario : Home Currency is USD
       //Type 1 : USD as base, eg EURUSD, GBPUSD
       //Type 2 : USD as quote, eg USDJPY, USDCAD
       //Type 3 : USD not in quote, but the base is the base for the pair with USD (eg GBPJPY <=> USDJPY)
       //Type 4 : USD not in quote, but the base is the quote for the pair with USD (eg GBPAUD <=> AUDUSD)
       
       if(StringFind(strInputSymbol,this.strBaseCurrency)>=0)
       {
           if(StringSubstr(strInputSymbol,3,3) == this.strBaseCurrency)
           {
                FinalType = 1;
           }
           else
           {
                FinalType = 2;
           }
       }
       else
       {
           string base = StringSubstr(strInputSymbol,3,3);
           for(int i = 0 ; i < ArraySize(symbol_list); i++)
           {
                if(StringSubstr(symbol_list[i],0,3) == this.strBaseCurrency &&
                   StringSubstr(symbol_list[i],3,3) == base
                  )
                 {
                      FinalType = 3;
                      break;
                 }
                
                if(StringSubstr(symbol_list[i],3,3) == this.strBaseCurrency &&
                   StringSubstr(symbol_list[i],0,3) == base
                  )
                 {
                      FinalType = 4;
                      break;
                 }
                
           }
       }
    }
    if(INST_TYPE.intType == 2)
    {
        FinalType = 5; //METALS
    }
    if(INST_TYPE.intType == 3)
    {
        FinalType = 6; //ENERGY
    }
    if(INST_TYPE.intType == 4)
    {
        FinalType = 7; //indices
    }
    if(INST_TYPE.intType == 5)
    {
        FinalType = 8; //futures
    }
    if(INST_TYPE.intType == 6)
    {
        FinalType = 9; //others
    }
    return(FinalType);
}

double clsMoneyManagement::dblPipValuePerLot (string strInputSymbol)
{
   //1 PIP equivalent to how many $ in term of USD per lot trading
   //Pip Value = (One Pip / Exchange Rate) * Lot Size
   //General formula is : (Close-Open) * Contract Size * Lot
   int symbol_type = this.intSymbolType(strInputSymbol);
   clsInstrumentType INST(strInputSymbol);
   strInputSymbol = INST.strFinalName;
   double base_rate = 0;
   double  digit = 0;
   double final_value = 0;
   double price_movement = 0;
   string pair_symbol = "";
   double pair_symbol_price = 0;
   switch(symbol_type)
   {
        case 1:
            base_rate   = MarketInfo(strInputSymbol,MODE_ASK);
            final_value = (pips(strInputSymbol)/base_rate * base_rate * this.dblContractSize(strInputSymbol));
            break;
        case 2:
            base_rate   = MarketInfo(strInputSymbol,MODE_ASK);
            final_value = (pips(strInputSymbol)/base_rate * this.dblContractSize(strInputSymbol));
            break;
        case 3:
            pair_symbol = this.strFindSameBaseHomeQuote(strInputSymbol);
            digit = MarketInfo(pair_symbol,MODE_DIGITS); 
            if(digit == 2 || digit == 3)
            {
              base_rate     = MarketInfo(pair_symbol,MODE_ASK) / 100;
            }
            else
            {
              base_rate     = MarketInfo(pair_symbol,MODE_ASK);
            }
            if(IsTesting() && base_rate == 0) base_rate = 1;
            final_value = 10/base_rate;
            break;
        case 4:
            pair_symbol = this.strFindOppositeHomeQuote(strInputSymbol);
            pair_symbol_price = MarketInfo(pair_symbol,MODE_ASK);
            if(IsTesting() && pair_symbol_price == 0) pair_symbol_price = 1;
            base_rate   = 1/pair_symbol_price;
            final_value = pips(strInputSymbol)/base_rate * this.dblContractSize(strInputSymbol);
            break;
        case 5: //metal
            //metal not calling for pip, but called as 0.01, one pip = 0.01 movement
            //formula = 0.1 * Contract size * lot size(1)
            price_movement = 0.1;
            final_value = price_movement * this.dblContractSize(strInputSymbol) * 1;
            break;
        case 6: //energy
            //energy not calling for pip, but called as 0.1, one pip = 0.1 movement
            //formula = 0.01 * Contract size * lot size(1)
            price_movement = 0.01;
            final_value = price_movement * this.dblContractSize(strInputSymbol) * 1;
            break;
        case 7: //indices
            //indices not calling for pip, but called as Dollar, one pip = one dollar movement
            //formula = 1 dollar (pip) * Contract size * lot size(1)
            price_movement = 1;
            final_value = price_movement * this.dblContractSize(strInputSymbol) * 1;
            break;
        case 8: //futures
            //futures not calling for pip, but called as 0.1, one pip = 0.1 movement
            //formula = 0.1 * Contract size * lot size(1)
            price_movement = 0.1;
            final_value = price_movement * this.dblContractSize(strInputSymbol) * 1;
            break;
        case 9: //others
            //others not calling for pip, but called as 0.1, one pip = 0.1 movement
            //formula = 0.1 * Contract size * lot size(1)
            //we need automatch from contract size, here we always presume pip value per lot is 10
            final_value     = 10;
            if(this.dblContractSize(strInputSymbol) == 0)
            {
                 Alert(strInputSymbol, " Not Match with Current MT4 Symbol List, Please Check");
            }
            else
            {
                 price_movement  = 10/this.dblContractSize(strInputSymbol);
            }
            break;
   }
   //Alert("Gold here with final value ",final_value);
   return(final_value);
   
   
}

double clsMoneyManagement::dblLotSizePerMoney(double dblInputMoney, string strInputSymbol, double dblSLPip)
{
   double lot_value     = this.dblPipValuePerLot(strInputSymbol);
   //Print("Symbol is ",strInputSymbol," with lot value of ",lot_value);
   //Print(strInputSymbol," lot value is ",lot_value);
   double money_to_risk = dblInputMoney;
   //Print(strInputSymbol," Money to Risk is ",money_to_risk);
   double risk_1_pip    = money_to_risk /dblSLPip;
   double final_lot     = risk_1_pip/lot_value;
   return(MathMax(final_lot,0.01)); // this is to keep min lot always greater or equal to 0.01
}

int clsMoneyManagement::intMultipleOfTen(double value)
{
    for(int i = 1; i < 10; i++)
    {
        double divisor = MathPow(10,i);
        if( (value/divisor) >= 0 && (value/divisor) < 10)
        {
             return(i);
        }
    }
    return(0);
}

int clsMoneyManagement::intSlPipPerPerMoney(double dblInputMoney, string strInputSymbol, double &dblLot)
{
    //WE DO AN AUTO LOT READJUSTMENT BY USING REF
    double lot_value     = this.dblPipValuePerLot(strInputSymbol);
    double money_to_risk = dblInputMoney;
    double risk_1_pip    = dblLot * lot_value;
    int _sl_pip           = (int)(money_to_risk/risk_1_pip);
    clsInstrumentType INST(strInputSymbol);
    double bid = MarketInfo(strInputSymbol,MODE_BID);
    if(bid == 0)
    {
       strInputSymbol = INST.strFinalName;
       bid = MarketInfo(strInputSymbol,MODE_BID);
    }
    
    double sl            = _sl_pip * pips(strInputSymbol);
    Alert("Sl pip is ",_sl_pip);
    Alert("Pip inside is ",pips(strInputSymbol));
    Alert("Sl is ",sl);
    //Alert("Bid is ",bid);
    int symbol_10_multp  = this.intMultipleOfTen(bid);
    int sl_10_multp      = this.intMultipleOfTen(sl);
    if(sl_10_multp >= symbol_10_multp && INST.intType != 1)
    {
        //we automatically do lot readjustment
        Alert("SL is ",sl);
        Alert("Lot Size input of ",dblLot," is too small for ",strInputSymbol);
        //READJUST LOT
        int factor = sl_10_multp/symbol_10_multp;
        dblLot = dblLot * MathPow(10,factor);
        _sl_pip = int(_sl_pip * MathPow(10,-factor));
        Alert("Auto Readjust Lot of ",strInputSymbol," to ",dblLot);
    }
    return _sl_pip;
}


double clsMoneyManagement::dblLotSizePerRisk(string strInputSymbol, double dblSLPip, int type=1)
{
   //type 1 : account balance
   //type 2 : account equity
   double lot_value     = this.dblPipValuePerLot(strInputSymbol);
   //Print("Symbol is ",strInputSymbol," with lot value of ",lot_value);
   //Print(strInputSymbol," lot value is ",lot_value);
   double ref_balance = type==1 ? this.dblAccountBalance : this.dblAccountEquity;
   double money_to_risk = this.dblRiskPercent / 100 * ref_balance;
   //Print(strInputSymbol," Money to Risk is ",money_to_risk);
   double risk_1_pip    = money_to_risk /dblSLPip;
   double final_lot     = risk_1_pip/lot_value;
   return(MathMax(final_lot,0.01)); // this is to keep min lot always greater or equal to 0.01
}

string clsMoneyManagement::strFindOppositeHomeQuote(string strInputSymbol)
{
     string value = "";
     for(int i = 0 ; i < ArraySize(symbol_list); i++)
     {
          if(StringFind(symbol_list[i],this.strBaseCurrency)>=0     &&
             StringSubstr(symbol_list[i],0,3) == StringSubstr(strInputSymbol,3,3)
            )
           {
               value = symbol_list[i];
               break;
           }
     }
     return(value);
}

string clsMoneyManagement::strFindSameBaseHomeQuote(string strInputSymbol)
{
     //eg GBPAUD vs AUDUSD
     string value = "";
     for(int i = 0 ; i < ArraySize(symbol_list); i++)
     {
          if(StringSubstr(symbol_list[i],0,3) == this.strBaseCurrency &&
             StringSubstr(symbol_list[i],3,3) == StringSubstr(strInputSymbol,3,3)
            )
           {
               value = symbol_list[i];
               break;
           }
     }
     return(value);
}

double clsMoneyManagement::dblIndMarginRequired(string strInputSymbol,double dblInputLot)
{
    
    //Required Margin = Trade Size / Leverage * Account Currency Exchange Rate
    double req_margin = dblInputLot * this.dblContractSize(strInputSymbol) / this.dblAccountLeverage * MarketInfo(strInputSymbol,MODE_ASK);
    
    int symbol_type = this.intSymbolType(strInputSymbol);
    string symbol_pair;
    switch(symbol_type)
    {
        case 1:
            //do nothing
            break;
        case 2:
           symbol_pair = this.strFindSameBaseHomeQuote(strInputSymbol);
           req_margin = req_margin/MarketInfo(symbol_pair,MODE_ASK);
            break;
        case 3:
            symbol_pair = this.strFindSameBaseHomeQuote(strInputSymbol);
            req_margin = req_margin/MarketInfo(symbol_pair,MODE_ASK);
            break;
        case 4:
            symbol_pair = this.strFindOppositeHomeQuote(strInputSymbol);
            req_margin = req_margin*MarketInfo(symbol_pair,MODE_ASK);
            break;
    }
    
    return(req_margin);
    
    
}


double clsMoneyManagement::dblMarginRequired(SIGNAL_LIST &signal[])
{
   double value = 0;
   int size = ArraySize(signal);
   if(size > 0)
   {
       
       for(int i = 0; i < size; i++)
       {
            //Print("Signal Is ",signal[i]._symbol);
            double lot = this.dblLotSizePerRisk(signal[i]._symbol,signal[i]._sl_pip);
            signal[i]._lot = lot;
            value += this.dblIndMarginRequired(signal[i]._symbol,lot);
       }
   }
   return(value);
}

double clsMoneyManagement::dblMarginToBase(string margin_cur, string base_cur, double margin_cur_value)
{
   if(IsTesting())return(1);
   double value = 0;
   string matching_currency = "";
   int margin_cur_pos = -1;
   int base_cur_pos   = -1;
   for(int i = 0 ; i < ArraySize(symbol_list); i++)
   {
       margin_cur_pos = StringFind(symbol_list[i],margin_cur);
       base_cur_pos   = StringFind(symbol_list[i],base_cur);
       //StringSubstr
       if(margin_cur_pos >= 0 && base_cur_pos >= 0)
       {
            matching_currency = symbol_list[i];
            break;
       }
   }
   if(matching_currency != "")
   {
       if(MarketInfo(matching_currency,MODE_BID) == 0)
       {
            Alert("Symbol Pre-fix and Post-Fix not set, please check");
            ExpertRemove();
       }
       else
       {
           if(margin_cur_pos < base_cur_pos)
           {
                value = margin_cur_value * MarketInfo(matching_currency,MODE_BID);
           }
           else
           {
                value = margin_cur_value * 1 / MarketInfo(matching_currency,MODE_BID);
           }
       }      
   }
   return(value);
}