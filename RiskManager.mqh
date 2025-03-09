//+------------------------------------------------------------------+
//|                             RiskManager.mqh                       |
//|                  Copyright 2025, Trading Systems Development       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Trading Systems Development"
#property link      "https://www.mql5.com"

#include "../Utils/Common.mqh"
#include "../Core/MarketStructure.mqh"

//+------------------------------------------------------------------+
//| Class for Risk Management                                         |
//+------------------------------------------------------------------+
class CRiskManager {
private:
   // Risk control parameters
   double m_baseRiskPercent;
   double m_maxRiskPercent;
   double m_minRiskRewardRatio;
   double m_maxTotalDrawdown;
   double m_maxDailyDrawdown;
   double m_minLotSize;
   double m_maxLotSize;
   bool m_useDynamicRiskControl;
   bool m_isPropFirmMode;
   int m_consecutiveLossLimit;
   double m_volatilityAdjustmentFactor;
   
   // Account statistics
   double m_initialBalance;
   double m_lastEquity;
   double m_dailyStartEquity;
   double m_weeklyStartEquity;
   double m_dailyHighWaterMark;
   double m_absoluteHighWaterMark;
   int m_consecutiveLosses;
   
   // Market variables
   string m_symbol;
   double m_currentATR;
   ENUM_RISK_PROFILE m_riskProfile;
   
   // Helper methods
   double AdjustRiskForVolatility(double baseRisk, double volatility);
   double AdjustRiskForDrawdown(double risk);
   double AdjustRiskForConsecutiveLosses(double risk);
   double GetMaxPositionSize();
   bool IsDailyDrawdownExceeded();
   bool IsTotalDrawdownExceeded();
   bool IsConsecutiveLossLimitExceeded();
   double CalculateStopLossPips(ENUM_SL_TYPE slType, double atr, double minSLPips, double maxSLPips);
   
public:
   // Constructor
   CRiskManager(
      string symbol,
      ENUM_RISK_PROFILE riskProfile = RISK_BALANCED,
      double baseRiskPercent = 1.0,
      double maxRiskPercent = 2.0,
      double minRiskRewardRatio = 1.5,
      double maxTotalDrawdown = 5.0,
      double maxDailyDrawdown = 3.0,
      bool useDynamicRiskControl = true,
      bool isPropFirmMode = false,
      int consecutiveLossLimit = 3,
      double volatilityAdjustmentFactor = 0.7,
      double minLotSize = 0.01,
      double maxLotSize = 0.0 // 0 means no limit
   );
   
   // Destructor
   ~CRiskManager() {};
   
   // Initialize account statistics
   void Initialize();
   
   // Update account statistics (call on each tick)
   void Update();
   
   // Calculate position size based on risk parameters
   double CalculateLotSize(
      double entryPrice,
      double stopLossPrice,
      double riskOverridePercent = 0.0
   );
   
   // Calculate SL and TP levels
   double CalculateStopLoss(
      int orderType,           // 0 = buy, 1 = sell
      double entryPrice,
      ENUM_SL_TYPE slType,
      double atr,
      double minSLPips = 0.0,
      double maxSLPips = 0.0
   );
   
   double CalculateTakeProfit(
      int orderType,           // 0 = buy, 1 = sell
      double entryPrice,
      double stopLossPrice,
      double tpRatio = 0.0     // If 0, use default minRiskRewardRatio
   );
   
   // Check if trading is allowed based on risk parameters
   bool IsTradingAllowed();
   
   // Check if specific order can be opened
   bool CanOpenOrder(
      int orderType,          // 0 = buy, 1 = sell
      double entryPrice,
      double stopLossPrice,
      double volume
   );
   
   // Track completed trade and update statistics
   void TrackCompletedTrade(double profit, bool isWin);
   
   // Calculate current drawdown
   double GetCurrentDrawdown();
   
   // Calculate daily profit/loss
   double GetDailyProfitLoss();
   
   // Calculate weekly profit/loss
   double GetWeeklyProfitLoss();
   
   // Get current equity and balance
   double GetCurrentEquity();
   double GetCurrentBalance();
   
   // Update risk profile
   void SetRiskProfile(ENUM_RISK_PROFILE profile);
   
   // Set ATR value for calculations
   void SetATR(double atr) { m_currentATR = atr; }
   
   // Get risk profile
   ENUM_RISK_PROFILE GetRiskProfile() const { return m_riskProfile; }
   
   // Check prop firm rules
   bool IsPropFirmRulesViolated();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager(
   string symbol,
   ENUM_RISK_PROFILE riskProfile,
   double baseRiskPercent,
   double maxRiskPercent,
   double minRiskRewardRatio,
   double maxTotalDrawdown,
   double maxDailyDrawdown,
   bool useDynamicRiskControl,
   bool isPropFirmMode,
   int consecutiveLossLimit,
   double volatilityAdjustmentFactor,
   double minLotSize,
   double maxLotSize
) : m_symbol(symbol),
    m_riskProfile(riskProfile),
    m_baseRiskPercent(baseRiskPercent),
    m_maxRiskPercent(maxRiskPercent),
    m_minRiskRewardRatio(minRiskRewardRatio),
    m_maxTotalDrawdown(maxTotalDrawdown),
    m_maxDailyDrawdown(maxDailyDrawdown),
    m_useDynamicRiskControl(useDynamicRiskControl),
    m_isPropFirmMode(isPropFirmMode),
    m_consecutiveLossLimit(consecutiveLossLimit),
    m_volatilityAdjustmentFactor(volatilityAdjustmentFactor),
    m_minLotSize(minLotSize),
    m_maxLotSize(maxLotSize),
    m_currentATR(0.0)
{
   // Initialize account statistics
   Initialize();
}

//+------------------------------------------------------------------+
//| Initialize account statistics                                     |
//+------------------------------------------------------------------+
void CRiskManager::Initialize() {
   // Get current account values
   m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   m_lastEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   m_dailyStartEquity = m_lastEquity;
   m_weeklyStartEquity = m_lastEquity;
   m_dailyHighWaterMark = m_lastEquity;
   m_absoluteHighWaterMark = m_lastEquity;
   m_consecutiveLosses = 0;
   
   // Adjust risk parameters for PropFirm mode
   if(m_isPropFirmMode) {
      // Override with more conservative values for prop firm
      m_baseRiskPercent = MathMin(m_baseRiskPercent, 0.5);
      m_maxRiskPercent = MathMin(m_maxRiskPercent, 1.0);
      m_maxTotalDrawdown = MathMin(m_maxTotalDrawdown, 4.0);
      m_maxDailyDrawdown = MathMin(m_maxDailyDrawdown, 2.0);
      
      // Set risk profile to prop firm
      m_riskProfile = RISK_PROP_FIRM;
   }
   
   // Adjust risk based on risk profile
   switch(m_riskProfile) {
      case RISK_CONSERVATIVE:
         m_baseRiskPercent = MathMin(m_baseRiskPercent, 0.75);
         m_maxRiskPercent = MathMin(m_maxRiskPercent, 1.25);
         break;
         
      case RISK_BALANCED:
         // No change from initial settings
         break;
         
      case RISK_AGGRESSIVE:
         m_baseRiskPercent = MathMin(1.5, m_baseRiskPercent * 1.25);
         m_maxRiskPercent = MathMin(2.5, m_maxRiskPercent * 1.25);
         break;
         
      case RISK_PROP_FIRM:
         m_baseRiskPercent = MathMin(m_baseRiskPercent, 0.5);
         m_maxRiskPercent = MathMin(m_maxRiskPercent, 1.0);
         m_maxTotalDrawdown = MathMin(m_maxTotalDrawdown, 4.0);
         m_maxDailyDrawdown = MathMin(m_maxDailyDrawdown, 2.0);
         break;
   }
}

//+------------------------------------------------------------------+
//| Update account statistics (call on each tick)                     |
//+------------------------------------------------------------------+
void CRiskManager::Update() {
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   // Check for day change
   static datetime lastDay = 0;
   datetime currentTime = TimeCurrent();
   MqlDateTime timeStruct;
   TimeToStruct(currentTime, timeStruct);
   
   // New day check
   if(lastDay != 0 && timeStruct.day != TimeDay(lastDay)) {
      // Reset daily statistics
      m_dailyStartEquity = currentEquity;
      m_dailyHighWaterMark = currentEquity;
   }
   
   // Check for week change
   static int lastWeek = 0;
   if(lastWeek != 0 && timeStruct.day_of_week < lastWeek) {
      // Reset weekly statistics
      m_weeklyStartEquity = currentEquity;
   }
   
   // Update high water marks
   if(currentEquity > m_dailyHighWaterMark) {
      m_dailyHighWaterMark = currentEquity;
   }
   
   if(currentEquity > m_absoluteHighWaterMark) {
      m_absoluteHighWaterMark = currentEquity;
   }
   
   // Update time tracking
   lastDay = currentTime;
   lastWeek = timeStruct.day_of_week;
   
   // Update current equity
   m_lastEquity = currentEquity;
}

//+------------------------------------------------------------------+
//| Calculate position size based on risk parameters                  |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(
   double entryPrice,
   double stopLossPrice,
   double riskOverridePercent = 0.0
) {
   if(entryPrice <= 0 || stopLossPrice <= 0 || entryPrice == stopLossPrice)
      return m_minLotSize;
   
   // Calculate risk amount
   double riskPercent = (riskOverridePercent > 0) ? riskOverridePercent : m_baseRiskPercent;
   
   // Apply dynamic risk adjustments if enabled
   if(m_useDynamicRiskControl) {
      // Adjust for volatility
      if(m_currentATR > 0) {
         double normalATR = SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 50; // Typical ATR value
         double volatilityRatio = m_currentATR / normalATR;
         riskPercent = AdjustRiskForVolatility(riskPercent, volatilityRatio);
      }
      
      // Adjust for drawdown
      riskPercent = AdjustRiskForDrawdown(riskPercent);
      
      // Adjust for consecutive losses
      riskPercent = AdjustRiskForConsecutiveLosses(riskPercent);
   }
   
   // Get account equity
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   // Calculate risk amount in account currency
   double riskAmount = equity * (riskPercent / 100.0);
   
   // Calculate SL distance in points
   double slDistance = MathAbs(entryPrice - stopLossPrice);
   
   // Get symbol specifications
   double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   
   // Calculate potential loss per lot
   double pointsPerTick = SymbolInfoDouble(m_symbol, SYMBOL_POINT) / tickSize;
   double ticksInSL = slDistance / tickSize;
   double lossPerLot = ticksInSL * tickValue;
   
   if(lossPerLot <= 0)
      return m_minLotSize;
   
   // Calculate position size
   double positionSize = riskAmount / lossPerLot;
   
   // Round to lot step
   positionSize = MathFloor(positionSize / lotStep) * lotStep;
   
   // Apply min/max limits
   positionSize = MathMax(positionSize, m_minLotSize);
   
   if(m_maxLotSize > 0) {
      positionSize = MathMin(positionSize, m_maxLotSize);
   }
   
   // Apply max position size based on account
   positionSize = MathMin(positionSize, GetMaxPositionSize());
   
   return positionSize;
}

//+------------------------------------------------------------------+
//| Calculate stop loss level based on selected method                |
//+------------------------------------------------------------------+
double CRiskManager::CalculateStopLoss(
   int orderType,           // 0 = buy, 1 = sell
   double entryPrice,
   ENUM_SL_TYPE slType,
   double atr,
   double minSLPips = 0.0,
   double maxSLPips = 0.0
) {
   if(entryPrice <= 0 || atr <= 0)
      return 0;
   
   // Convert pips to price if provided
   double minSL = (minSLPips > 0) ? PipsToPrice(m_symbol, minSLPips) : 0;
   double maxSL = (maxSLPips > 0) ? PipsToPrice(m_symbol, maxSLPips) : 0;
   
   // Calculate SL distance based on method
   double slDistance = 0;
   
   switch(slType) {
      case SL_TYPE_ATR:
         // ATR-based stop loss
         slDistance = atr * 1.5; // Default multiplier
         break;
         
      case SL_TYPE_PIVOT:
         // Based on recent swing points (simplified)
         slDistance = atr * 2.0;
         break;
         
      case SL_TYPE_COMBINED:
         // Combined approach
         slDistance = atr * 1.8;
         break;
         
      case SL_TYPE_ADAPTIVE:
         // Adaptive based on market conditions
         if(m_currentATR > atr * 1.5) {
            // Higher volatility = wider stop
            slDistance = atr * 2.0;
         } else {
            // Normal volatility
            slDistance = atr * 1.5;
         }
         break;
         
      default:
         slDistance = atr * 1.5;
         break;
   }
   
   // Apply min/max constraints
   if(minSL > 0 && slDistance < minSL)
      slDistance = minSL;
   
   if(maxSL > 0 && slDistance > maxSL)
      slDistance = maxSL;
   
   // Calculate SL price
   double stopLossPrice = 0;
   
   if(orderType == 0) {
      // Buy order - SL below entry
      stopLossPrice = entryPrice - slDistance;
   } else {
      // Sell order - SL above entry
      stopLossPrice = entryPrice + slDistance;
   }
   
   return stopLossPrice;
}

//+------------------------------------------------------------------+
//| Calculate take profit based on stop loss and risk:reward          |
//+------------------------------------------------------------------+
double CRiskManager::CalculateTakeProfit(
   int orderType,           // 0 = buy, 1 = sell
   double entryPrice,
   double stopLossPrice,
   double tpRatio = 0.0     // If 0, use default minRiskRewardRatio
) {
   if(entryPrice <= 0 || stopLossPrice <= 0 || entryPrice == stopLossPrice)
      return 0;
   
   // Use provided ratio or default
   double ratio = (tpRatio > 0) ? tpRatio : m_minRiskRewardRatio;
   
   // Calculate SL distance
   double slDistance = MathAbs(entryPrice - stopLossPrice);
   
   // Calculate TP distance
   double tpDistance = slDistance * ratio;
   
   // Calculate TP price
   double takeProfitPrice = 0;
   
   if(orderType == 0) {
      // Buy order - TP above entry
      takeProfitPrice = entryPrice + tpDistance;
   } else {
      // Sell order - TP below entry
      takeProfitPrice = entryPrice - tpDistance;
   }
   
   return takeProfitPrice;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed based on risk parameters              |
//+------------------------------------------------------------------+
bool CRiskManager::IsTradingAllowed() {
   // Get equity and balance
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   // Check overall drawdown limit
   double totalDrawdownPercent = ((m_absoluteHighWaterMark - currentEquity) / m_absoluteHighWaterMark) * 100.0;
   if(totalDrawdownPercent > m_maxTotalDrawdown)
      return false;
   
   // Check daily drawdown limit
   double dailyDrawdownPercent = ((m_dailyHighWaterMark - currentEquity) / m_dailyHighWaterMark) * 100.0;
   if(dailyDrawdownPercent > m_maxDailyDrawdown)
      return false;
   
   // Check consecutive loss limit
   if(m_consecutiveLosses >= m_consecutiveLossLimit)
      return false;
   
   // Extra checks for prop firm mode
   if(m_isPropFirmMode) {
      // Check open margin
      double margin = AccountInfoDouble(ACCOUNT_MARGIN);
      double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      
      // Very conservative margin check for prop firms
      if(marginLevel < 500)
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if specific order can be opened                            |
//+------------------------------------------------------------------+
bool CRiskManager::CanOpenOrder(
   int orderType,
   double entryPrice,
   double stopLossPrice,
   double volume
) {
   if(!IsTradingAllowed())
      return false;
   
   if(entryPrice <= 0 || stopLossPrice <= 0 || volume <= 0)
      return false;
   
   // Calculate potential loss
   double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
   
   double slDistance = MathAbs(entryPrice - stopLossPrice);
   double ticksInSL = slDistance / tickSize;
   double potentialLoss = ticksInSL * tickValue * volume;
   
   // Get account equity
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   // Check if potential loss is within risk limits
   double riskPercent = (potentialLoss / equity) * 100.0;
   
   if(riskPercent > m_maxRiskPercent)
      return false;
   
   // Calculate risk:reward ratio
   double potential_tp = 0;
   if(orderType == 0) { // Buy
      potential_tp = entryPrice + (slDistance * m_minRiskRewardRatio);
   } else { // Sell
      potential_tp = entryPrice - (slDistance * m_minRiskRewardRatio);
   }
   
   // Check SL distance (avoid very tight stops)
   double minSLPips = 5.0; // Minimum 5 pips SL
   double minSLPrice = PipsToPrice(m_symbol, minSLPips);
   
   if(slDistance < minSLPrice)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Track completed trade and update statistics                       |
//+------------------------------------------------------------------+
void CRiskManager::TrackCompletedTrade(double profit, bool isWin) {
   // Update consecutive win/loss count
   if(isWin) {
      m_consecutiveLosses = 0;
   } else {
      m_consecutiveLosses++;
   }
}

//+------------------------------------------------------------------+
//| Calculate current drawdown                                        |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentDrawdown() {
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   // Calculate percent drawdown from peak
   return ((m_absoluteHighWaterMark - currentEquity) / m_absoluteHighWaterMark) * 100.0;
}

//+------------------------------------------------------------------+
//| Calculate daily profit/loss                                       |
//+------------------------------------------------------------------+
double CRiskManager::GetDailyProfitLoss() {
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   return currentEquity - m_dailyStartEquity;
}

//+------------------------------------------------------------------+
//| Calculate weekly profit/loss                                      |
//+------------------------------------------------------------------+
double CRiskManager::GetWeeklyProfitLoss() {
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   return currentEquity - m_weeklyStartEquity;
}

//+------------------------------------------------------------------+
//| Get current equity                                                |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentEquity() {
   return AccountInfoDouble(ACCOUNT_EQUITY);
}

//+------------------------------------------------------------------+
//| Get current balance                                               |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentBalance() {
   return AccountInfoDouble(ACCOUNT_BALANCE);
}

//+------------------------------------------------------------------+
//| Update risk profile                                               |
//+------------------------------------------------------------------+
void CRiskManager::SetRiskProfile(ENUM_RISK_PROFILE profile) {
   // Store previous profile for comparison
   ENUM_RISK_PROFILE previousProfile = m_riskProfile;
   
   // Set new profile
   m_riskProfile = profile;
   
   // Only reinitialize if profile actually changed
   if(previousProfile != profile) {
      Initialize();
   }
}

//+------------------------------------------------------------------+
//| Check if prop firm rules are violated                             |
//+------------------------------------------------------------------+
bool CRiskManager::IsPropFirmRulesViolated() {
   if(!m_isPropFirmMode)
      return false;
   
   // Get current metrics
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double initialAccountBalance = m_initialBalance;
   
   // Calculate total drawdown from initial balance
   double totalDrawdownPercent = ((initialAccountBalance - currentEquity) / initialAccountBalance) * 100.0;
   
   // Calculate daily drawdown from daily high water mark
   double dailyDrawdownPercent = ((m_dailyHighWaterMark - currentEquity) / m_dailyHighWaterMark) * 100.0;
   
   // Check total drawdown rule
   if(totalDrawdownPercent > m_maxTotalDrawdown)
      return true;
   
   // Check daily drawdown rule
   if(dailyDrawdownPercent > m_maxDailyDrawdown)
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Helper: Adjust risk percent based on volatility                   |
//+------------------------------------------------------------------+
double CRiskManager::AdjustRiskForVolatility(double baseRisk, double volatility) {
   // Reduce risk as volatility increases
   double adjustmentFactor = MathPow(m_volatilityAdjustmentFactor, volatility);
   
   // Apply adjustment
   return baseRisk * adjustmentFactor;
}

//+------------------------------------------------------------------+
//| Helper: Adjust risk percent based on current drawdown             |
//+------------------------------------------------------------------+
double CRiskManager::AdjustRiskForDrawdown(double risk) {
   // Get current drawdown
   double drawdownPercent = GetCurrentDrawdown();
   
   // Progressive reduction as drawdown increases
   double drawdownFactorThreshold = m_maxTotalDrawdown * 0.5; // Half of max drawdown
   
   if(drawdownPercent > drawdownFactorThreshold) {
      // Calculate how close we are to max drawdown (0-1 scale)
      double drawdownFactor = (drawdownPercent - drawdownFactorThreshold) / 
                             (m_maxTotalDrawdown - drawdownFactorThreshold);
      
      // Apply progressive reduction
      risk *= (1.0 - (drawdownFactor * 0.75));
   }
   
   return risk;
}

//+------------------------------------------------------------------+
//| Helper: Adjust risk percent based on consecutive losses           |
//+------------------------------------------------------------------+
double CRiskManager::AdjustRiskForConsecutiveLosses(double risk) {
   // Reduce risk after consecutive losses
   if(m_consecutiveLosses > 0) {
      // Reduce by 20% for each consecutive loss
      double reductionFactor = MathPow(0.8, MathMin(m_consecutiveLosses, 3));
      
      // Apply reduction
      risk *= reductionFactor;
   }
   
   return risk;
}

//+------------------------------------------------------------------+
//| Helper: Get maximum position size based on account                |
//+------------------------------------------------------------------+
double CRiskManager::GetMaxPositionSize() {
   double maxSize = 0;
   
   // Use account free margin and leverage to determine max position size
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   
   if(leverage <= 0)
      leverage = 100; // Default assumption
   
   // Get contract specification for margin calculation
   double contractSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double marginRate = SymbolInfoDouble(m_symbol, SYMBOL_MARGIN_INITIAL);
   
   if(marginRate <= 0)
      marginRate = 1.0; // Fallback value
   
   // Get current price
   double price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   
   if(price <= 0)
      return m_minLotSize;
   
   // Calculate max size based on free margin
   maxSize = (freeMargin * leverage) / (contractSize * price * marginRate);
   
   // Apply conservative 30% limit of max position size for safety
   maxSize *= 0.3;
   
   // Round to lot step
   double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   maxSize = MathFloor(maxSize / lotStep) * lotStep;
   
   return maxSize;
} 