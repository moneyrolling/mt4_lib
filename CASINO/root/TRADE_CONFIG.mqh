struct TRADE_COMMAND // 
{
   int     _action; // default is setting to 0, which mean to open trade; 1 is for MODIFY; 2 is CLOSE; 3 os for delete
   int     _order_type; //0 - OP_BUY; 1 - OP_SELL; 2 - OP_BUYLIMIT; 3 - OP_SELLLIMIT; 4 - OP_BUYSTOP; 5 - OP_SELLSTOP
   string  _symbol;
   double  _lots;
   double  _entry;
   double  _sl;
   double  _tp;
   int     _magic;
   int     _ticket_number;
   string  _comment;
   datetime _expiry;
   string  _trade_entry_tag;
   //BREAKEVEN 
   int     _breakeven_mode;
   double  _breakeven_input;
   double  _breakeven_buffer;
   //TRAILING
   int     _trailing_mode; // 1 standard trailing by Fixed Pip, 2 trailing by User Input SL
   double  _trailing_input; //if mode is 1, the responding variable will be pip, if 2 then factor
   //HEDGE
   bool    _hedge_trade;
   bool    _hedge_assist_trade;
   bool    _hedge_internal_trade;
   double  _saved_lot;
   bool    _recover_mother;
   int     _recover_source;
   int     _recover_count;
   int     _reverse_source;
   int     _reverse_count;
   double  _recover_be_price;
   bool    _recover_trail_start;
   int     _reverse_jie_source;
   int     _reverse_jie_count;
   bool    _reverse_jie_in_loss;
   int     _roulette_source;
   int     _roulette_count;
   bool    _roulette_in_win;
   double            _grid_tag;      //we use initial grid opening price
   int               _grid_count;    //total grid number to open
   double            _grid_distance; //spacing for each distance (in pips)
   double            _grid_base_lot;
   double            _grid_multiplier;
   double            _grid_sl_pip;
   double            _grid_tp_pip;
   int               _angry_martin_source;
   int               _angry_martin_count;
   int               _angry_martin_distance;
   double            _angry_martin_base_lot;
   int               _yoav_source;
   int               _yoav_count;
   double            _yoav_base_lot;
   double            _yoav_latest_tp;
   TRADE_COMMAND() : _action(-1),_order_type(-1),_symbol(""),_lots(0),_entry(0),_sl(0),_tp(0),_magic(0),_comment(""),_expiry(0),_trade_entry_tag(""),
                     _breakeven_mode(0),_breakeven_input(0),_breakeven_buffer(0),
                     _trailing_mode(0),_trailing_input(0),_hedge_trade(false),_hedge_assist_trade(false),_hedge_internal_trade(false),_saved_lot(0),
                     _recover_mother(false),_recover_source(0),_recover_count(0),_recover_be_price(0),_recover_trail_start(false),
                     _reverse_source(0),_reverse_count(0),
                     _reverse_jie_source(0),_reverse_jie_count(0),_reverse_jie_in_loss(false),
                     _roulette_source(0),_roulette_count(0),_roulette_in_win(false),
                     _grid_tag(0),_grid_count(0),_grid_distance(0),_grid_base_lot(0),_grid_multiplier(0),_grid_sl_pip(0),_grid_tp_pip(0),
                     _angry_martin_source(0),_angry_martin_count(0),_angry_martin_distance(0),_angry_martin_base_lot(0),
                     _yoav_source(0),_yoav_count(0),_yoav_base_lot(0),_yoav_latest_tp(0)
                     {};
};

struct TRADE_LIST
  {
   bool              _active;
   int               _order_type; //0 - OP_BUY; 1 - OP_SELL; 2 - OP_BUYLIMIT; 3 - OP_SELLLIMIT; 4 - OP_BUYSTOP; 5 - OP_SELLSTOP
   int               _ticket_number;
   string            _order_symbol;
   double            _order_lot;
   double            _open_price;
   double            _close_price;
   double            _entry;
   double            _stop_loss;
   double            _take_profit;
   double            _order_profit;
   double            _order_swap;
   datetime          _last_swap_record_date;
   double            _order_comission;
   datetime          _order_opened_time;
   datetime          _order_closed_time;
   datetime          _order_expiry;
   int               _magic_number;
   string            _order_comment;
   string            _trade_entry_tag;
   //HEDGE
   bool              _hedge_trade;
   bool              _hedge_assist_trade;
   bool              _hedge_internal_trade;
   double            _saved_lot;
   int               _reverse_source;
   int               _reverse_count;
   bool              _recover_mother;
   int               _recover_source;
   int               _recover_count;
   double            _recover_be_price;
   bool              _recover_trail_start;
   int               _reverse_jie_source;
   int               _reverse_jie_count;
   bool              _reverse_jie_in_loss;
   int               _roulette_source;
   int               _roulette_count;
   bool              _roulette_in_win;
   double            _grid_tag;      //we use initial grid opening price
   int               _grid_count;    //total grid number to open
   double            _grid_distance; //spacing for each distance (in pips)
   double            _grid_base_lot;
   double            _grid_multiplier;
   double            _grid_sl_pip;
   double            _grid_tp_pip;
   int               _angry_martin_source;
   int               _angry_martin_count;
   int               _angry_martin_distance;
   double            _angry_martin_base_lot;
   int               _yoav_source;
   int               _yoav_count;
   double            _yoav_base_lot;
   double            _yoav_latest_tp;
   bool              _breakeven_tag;
   bool              _trailed_tag;
   
   TRADE_LIST() : _active(false),_order_type(-1),_ticket_number(0),_order_symbol(""),_order_lot(0),
                  _open_price(0),_close_price(0),_entry(0),_stop_loss(0),
                  _take_profit(0),_order_profit(0),_order_swap(0), _order_comission(0),
                  _order_opened_time(0),_order_closed_time(0),_order_expiry(0),_magic_number(0),
                  _order_comment(""),_trade_entry_tag(""),_hedge_trade(false),_hedge_assist_trade(false),_hedge_internal_trade(false), _saved_lot(0), _reverse_source(0), _reverse_count(0), _recover_mother(false), _recover_source(0), _recover_count(0),_recover_be_price(0),_recover_trail_start(false),
                  _reverse_jie_source(0),_reverse_jie_count(0),_reverse_jie_in_loss(false),
                  _roulette_source(0),_roulette_count(0),_roulette_in_win(false),
                  _grid_tag(0),_grid_count(0),_grid_distance(0),_grid_base_lot(0),_grid_multiplier(0),_grid_sl_pip(0),_grid_tp_pip(0),
                  _angry_martin_source(0),_angry_martin_count(0),_angry_martin_distance(0),_angry_martin_base_lot(0),
                  _yoav_source(0),_yoav_count(0),_yoav_base_lot(0),_yoav_latest_tp(0),
                  _breakeven_tag(false),_trailed_tag(false)
                  {}; //INITIALIZE DEFAULT WITH ZERO VALUE
  };