#include "MASTER_CONFIG.mqh"
#include "CANVAS_BASE.mqh"
extern double Renko_Box_Size = 25;

struct CUSTOM_BAR{
    double _open;
    double _high;
    double _low;
    double _close;
    datetime _time;
    CUSTOM_BAR() : _open(0),_high(0),_low(0),_close(0),_time(0) {}; //INITIALIZE DEFAULT WITH ZERO VALUE
};

class clsCustomBar {
    
    public:
       clsCustomBar(string strInputSymbol);
       ~clsCustomBar();
       void          RenkoCloseUpdater(datetime time, double price);
       void          MedianRenkoCloseUpdater(datetime time,double price);
       void          RenkoOHLCUpdater(datetime time, double price);
       void          MedianRenkoOHLCUpdater(datetime time,double open, double high, double low, double close);
       void          AddBar(CUSTOM_BAR &bar, CUSTOM_BAR &bar_list[]);
       void          DrawBar();
       CUSTOM_BAR    BAR_LIST[];
       
    protected:
       bool          blValueExceed();
       void          ResetBackGround();
       void          SetBackGround();
       void          CreateWick(datetime time, double open, double high, double low, double close, datetime actual_time=0);
       void          CreateBody(datetime time, double open, double high, double low, double close, datetime actual_time=0);
       
       
    private:
       int           intBodySize;
       int           intWickSize;
       string        strSymbol;
       double        intRenkoBoxSize; 
       int           intMaxBar;
       string        strIdentifier;
       color         clrBull;
       color         clrBear;
       double        dblOpenPrev;
       double        dblHighPrev;
       double        dblLowPrev;
       double        dblClosePrev;
};

clsCustomBar::clsCustomBar(string strInputSymbol)
{
    strSymbol = strInputSymbol;
    intRenkoBoxSize = Renko_Box_Size;
    intBodySize = 12;
    intWickSize = 6;
    intMaxBar = 400;
    strIdentifier = "BAR";
    clrBull   = clrGreen;
    clrBear   = clrRed;
    //m_canvas.FillRectangle(0,0,100,100,ColorToARGB(clrBlack,255));
}

clsCustomBar::~clsCustomBar(void)
{
    ObjectDelete(0,strIdentifier);
    this.ResetBackGround();
}

void clsCustomBar::ResetBackGround(){
    /*
    ChartSetInteger(0,CHART_SHOW_GRID,0,this.ChartInitGrid);
    ChartSetInteger(0,CHART_COLOR_BACKGROUND,this.ChartInitBG);
    ChartSetInteger(0,CHART_COLOR_CHART_UP,this.ChartInitBull);
    ChartSetInteger(0,CHART_COLOR_CHART_DOWN,this.ChartInitBear);
    ChartSetInteger(0,CHART_FOREGROUND,this.ChartInitFG);
    */
    ChartSetInteger(0,CHART_SHOW_GRID,0,true);
    ChartSetInteger(0,CHART_COLOR_BACKGROUND,clrBlack);
    ChartSetInteger(0,CHART_COLOR_CHART_UP,clrBlue);
    ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrBlue);
    ChartSetInteger(0,CHART_COLOR_CHART_DOWN,clrRed);
    ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrRed);
    ChartSetInteger(0,CHART_COLOR_CHART_LINE,clrBlack);
    ChartSetInteger(0,CHART_FOREGROUND,clrWhite);
    
    //CHART_COLOR_CHART_LINE
}

void clsCustomBar::SetBackGround(){
    
    ChartSetInteger(0,CHART_FOREGROUND,0,false);
    color BG_COLOR = clrBlack;
    ChartSetInteger(0,CHART_SHOW_GRID,0,false);
    ChartSetInteger(0,CHART_COLOR_BACKGROUND,BG_COLOR);
    ChartSetInteger(0,CHART_COLOR_CHART_UP,BG_COLOR);
    ChartSetInteger(0,CHART_COLOR_CHART_DOWN,BG_COLOR);
    ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,BG_COLOR);
    ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,BG_COLOR);
    //ChartSetInteger(0,CHART_FOREGROUND,clrBlack);
}

void clsCustomBar::RenkoCloseUpdater(datetime time,double price)
{
    int cur_bar_size = ArraySize(BAR_LIST);
    if(cur_bar_size==0)
    {
        //We create new bar
        CUSTOM_BAR tmp_bar;
        tmp_bar._open  = price;
        tmp_bar._high  = price;
        tmp_bar._low   = price;
        tmp_bar._close = price;
        tmp_bar._time  = time;
        AddBar(tmp_bar,BAR_LIST);
    }
    else
    {
        if
        (
           price - BAR_LIST[0]._high > intRenkoBoxSize * pips(strSymbol) ||
           BAR_LIST[0]._low - price  > intRenkoBoxSize * pips(strSymbol)
           //MathAbs(BAR_LIST[0]._close - price) > intRenkoBoxSize * pips(strSymbol)
        )
        {
           int direction = 0;
           if(price - BAR_LIST[0]._high > intRenkoBoxSize * pips(strSymbol)) direction = 1;
           if(BAR_LIST[0]._low - price  > intRenkoBoxSize * pips(strSymbol)) direction = -1;
           if(direction == 1)  BAR_LIST[0]._close = BAR_LIST[0]._open + intRenkoBoxSize * pips(strSymbol);
           if(direction == -1) BAR_LIST[0]._close = BAR_LIST[0]._open - intRenkoBoxSize * pips(strSymbol);
           //BAR_LIST[0]._close = price;
           //create a new bar
           CUSTOM_BAR tmp_bar;
           tmp_bar._open  = BAR_LIST[0]._close;
           tmp_bar._high  = tmp_bar._open;//tmp_bar._open + intRenkoBoxSize * pips(strSymbol);
           tmp_bar._low   = tmp_bar._open;//price;
           tmp_bar._close = tmp_bar._open;//price;
           tmp_bar._time  = time;
           AddBar(tmp_bar,BAR_LIST);
        }
        else
        {
           if(price > BAR_LIST[0]._high) BAR_LIST[0]._high = price;
           if(price < BAR_LIST[0]._low)  BAR_LIST[0]._low  = price;
        }
    }
}


void clsCustomBar::MedianRenkoCloseUpdater(datetime time,double price)
{
    int cur_bar_size = ArraySize(BAR_LIST);
    if(cur_bar_size==0)
    {
        //We create new bar
        CUSTOM_BAR tmp_bar;
        tmp_bar._open  = price;
        tmp_bar._high  = price;
        tmp_bar._low   = price;
        tmp_bar._close = price;
        tmp_bar._time  = time;
        AddBar(tmp_bar,BAR_LIST);
    }
    else
    {
        if
        (
           price - BAR_LIST[0]._high > intRenkoBoxSize * pips(strSymbol) ||
           BAR_LIST[0]._low - price  > intRenkoBoxSize * pips(strSymbol)
           //MathAbs(BAR_LIST[0]._close - price) > intRenkoBoxSize * pips(strSymbol)
        )
        {
           int direction = 0;
           if(price - BAR_LIST[0]._high > intRenkoBoxSize * pips(strSymbol)) direction = 1;
           if(BAR_LIST[0]._low - price  > intRenkoBoxSize * pips(strSymbol)) direction = -1;
           if(direction == 1)  BAR_LIST[0]._close = BAR_LIST[0]._open + intRenkoBoxSize * pips(strSymbol);
           if(direction == -1) BAR_LIST[0]._close = BAR_LIST[0]._open - intRenkoBoxSize * pips(strSymbol);
           //BAR_LIST[0]._close = price;
           //create a new bar
           CUSTOM_BAR tmp_bar;
           tmp_bar._open  = MathMin(BAR_LIST[0]._close, BAR_LIST[0]._open) + (MathAbs(BAR_LIST[0]._close - BAR_LIST[0]._open)/2);
           tmp_bar._high  = tmp_bar._open;//tmp_bar._open + intRenkoBoxSize * pips(strSymbol);
           tmp_bar._low   = tmp_bar._open;//price;
           tmp_bar._close = tmp_bar._open;//price;
           tmp_bar._time  = time;
           AddBar(tmp_bar,BAR_LIST);
        }
        else
        {
           if(price > BAR_LIST[0]._high) BAR_LIST[0]._high = price;
           if(price < BAR_LIST[0]._low)  BAR_LIST[0]._low  = price;
        }
    }
}

void clsCustomBar::MedianRenkoOHLCUpdater(datetime time,double open, double high, double low, double close)
{
    int cur_bar_size = ArraySize(BAR_LIST);
    if(dblOpenPrev != 0)
    {
       if(cur_bar_size==0)
       {
           //We create new bar
           CUSTOM_BAR tmp_bar;
           tmp_bar._open  = close;
           tmp_bar._high  = close;
           tmp_bar._low   = close;
           tmp_bar._close = close;
           tmp_bar._time  = time;
           AddBar(tmp_bar,BAR_LIST);
       }
       else
       {
           if
           (
              high - BAR_LIST[0]._high  > intRenkoBoxSize * pips(strSymbol) ||
              high - BAR_LIST[0]._close > intRenkoBoxSize * pips(strSymbol) ||
              BAR_LIST[0]._low - low    > intRenkoBoxSize * pips(strSymbol) ||
              BAR_LIST[0]._close - low  > intRenkoBoxSize * pips(strSymbol)
              //MathAbs(BAR_LIST[0]._close - price) > intRenkoBoxSize * pips(strSymbol)
           )
           {
              int direction = 0;
              if(high - BAR_LIST[0]._high > intRenkoBoxSize * pips(strSymbol) ||
                 high - BAR_LIST[0]._close > intRenkoBoxSize * pips(strSymbol)
                ) 
              {  
                direction = 1;
              }
              if(BAR_LIST[0]._low - low    > intRenkoBoxSize * pips(strSymbol) ||
                 BAR_LIST[0]._close - low  > intRenkoBoxSize * pips(strSymbol)
                ) 
              {
                 direction = -1;
              }
              if(direction == 1)  BAR_LIST[0]._close = BAR_LIST[0]._open + intRenkoBoxSize * pips(strSymbol);
              if(direction == -1) BAR_LIST[0]._close = BAR_LIST[0]._open - intRenkoBoxSize * pips(strSymbol);
              
              
              //BAR_LIST[0]._close = price;
              //create a new bar
              CUSTOM_BAR tmp_bar;
              tmp_bar._open  = MathMin(BAR_LIST[0]._close, BAR_LIST[0]._open) + (MathAbs(BAR_LIST[0]._close - BAR_LIST[0]._open)/2);
              tmp_bar._high  = tmp_bar._open;//tmp_bar._open + intRenkoBoxSize * pips(strSymbol);
              tmp_bar._low   = tmp_bar._open;//price;
              tmp_bar._close = tmp_bar._open;//price;
              tmp_bar._time  = time;
              AddBar(tmp_bar,BAR_LIST);
           }
           else
           {
              if(high > BAR_LIST[0]._high) BAR_LIST[0]._high = high;
              if(low  < BAR_LIST[0]._low)  BAR_LIST[0]._low  = low;
           }
       }
    }
    dblOpenPrev  = open;
    dblHighPrev  = high;
    dblLowPrev   = low;
    dblClosePrev = close;
}

void clsCustomBar::AddBar(CUSTOM_BAR &bar, CUSTOM_BAR &bar_list[])
{
    int size = ArraySize(bar_list);
    CUSTOM_BAR new_list[];
    if(size < intMaxBar) 
    {
       ArrayResize(new_list,size+1);
       for(int i = size; i > 0; i--)
       {
           new_list[i] = bar_list[i-1];
       }
       new_list[0] = bar;
    }
    else
    {
       ArrayResize(new_list,intMaxBar);
       for(int i = size-1; i > 0; i--)
       {
           new_list[i] = bar_list[i-1];
       }
       new_list[0] = bar;
    }
    ArrayFree(bar_list);
    ArrayResize(bar_list,ArraySize(new_list));
    for(int i = 0; i < ArraySize(bar_list); i++)
    {
        bar_list[i] = new_list[i];
    }
}

bool clsCustomBar::blValueExceed()
{
    return(false);
}

void clsCustomBar::DrawBar()
{
    this.SetBackGround();
    for(int i = 1; i < ArraySize(BAR_LIST); i++)
    {
          datetime actual_time = BAR_LIST[i]._time;
          datetime time  = iTime(strSymbol,ChartPeriod(),i);
          double   open  = BAR_LIST[i]._open;
          double   high  = BAR_LIST[i]._open;
          double   low   = BAR_LIST[i]._low;
          double   close = BAR_LIST[i]._close;
          //if(time == BAR_LIST[i]._time)
          //{
             CreateWick(time,open,high,low,close,actual_time);
             CreateBody(time,open,high,low,close,actual_time);
          //}
    }
}

void clsCustomBar::CreateWick(datetime time, double open, double high, double low, double close, datetime actual_time=0)
{
    string name = strIdentifier + "_Wick_" + (string)actual_time;
    ObjectCreate(name,OBJ_TREND,0,time,high,time,low);
    ObjectSet(name,OBJPROP_STYLE,STYLE_SOLID);
    ObjectSet(name,OBJPROP_RAY,FALSE);
    ObjectSet(name,OBJPROP_WIDTH,intWickSize);
    ObjectSet(name,OBJPROP_TIME1,time);
    ObjectSet(name,OBJPROP_PRICE1,high);
    ObjectSet(name,OBJPROP_TIME2,time);
    ObjectSet(name,OBJPROP_PRICE2,low);
    ObjectSetInteger(0,name,OBJPROP_BACK,false);
    if(open<=close) ObjectSet(name,OBJPROP_COLOR,clrBull);
    else            ObjectSet(name,OBJPROP_COLOR,clrBear);
    
}

void clsCustomBar::CreateBody(datetime time, double open, double high, double low, double close, datetime actual_time=0)
{
    string name = strIdentifier + "_Body_" + (string)actual_time;
    ObjectCreate(name,OBJ_TREND,0,time,open,time,close);
    ObjectSet(name,OBJPROP_STYLE,STYLE_SOLID);
    ObjectSet(name,OBJPROP_RAY,FALSE);
    ObjectSet(name,OBJPROP_WIDTH,intBodySize);
    ObjectSet(name,OBJPROP_TIME1,time);
    ObjectSet(name,OBJPROP_PRICE1,open);
    ObjectSet(name,OBJPROP_TIME2,time);
    ObjectSet(name,OBJPROP_PRICE2,close);
    ObjectSetInteger(0,name,OBJPROP_BACK,false);
    if(open<=close) ObjectSet(name,OBJPROP_COLOR,clrBull);
    else            ObjectSet(name,OBJPROP_COLOR,clrBear);
}