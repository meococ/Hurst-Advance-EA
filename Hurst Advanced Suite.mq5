//+------------------------------------------------------------------+
//|                        Hurst Advanced Suite.mq5                   |
//|                  Copyright 2025, Trading Systems Development       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Trading Systems Development"
#property link      "https://www.mql5.com"
#property version   "3.50"

/*
 * HURST ADVANCED SUITE - ENHANCED PROFESSIONAL VERSION 
 * 
 * Advanced trading strategy combining:
 * - Hurst Exponent for market regime identification
 * - Fibonacci EMA system for trend detection
 * - Enhanced MACD divergence analysis
 * - Multi-level risk management
 * - Smart equity protection for prop firm challenges
 * - Dynamic trailing stop based on market structure
 * - Real-time volatility adjustments
 * - Multidimensional Confirmation Matrix for trade signals
 * - Advanced trendline detection and pattern recognition
 */

// Include các module chức năng
#include <Trade/Trade.mqh>
#include <Math/Stat/Math.mqh>
#include "Modules/Utils/Common.mqh"
#include "Modules/Core/HurstAnalysis.mqh"
#include "Modules/Core/MarketStructure.mqh"
#include "Modules/Strategy/SignalGeneration.mqh"
#include "Modules/Trade/PositionManager.mqh"
#include "Modules/Trade/RiskManager.mqh"

// Định nghĩa MODE cho MT5
#define MODE_MAIN 0
#define MODE_SIGNAL 1
#define MODE_UPPER 1
#define MODE_LOWER 2

//+------------------------------------------------------------------+
//| Các tham số đầu vào                                              |
//+------------------------------------------------------------------+

//--- Strategy & Risk Profile Setup
input group "=== Strategy & Risk Management ==="
input ENUM_RISK_PROFILE RiskProfile = RISK_BALANCED; // Risk Profile
input ENUM_SCALPING_MODE ScalpingMode = SCALPING_ALL; // Trading Strategy
input double BaseRiskPercent = 0.75;      // Base risk per trade (% equity)
input bool UseDynamicRiskControl = true;  // Dynamic risk control
input bool UseSmartExitStrategy = true;   // Smart exit strategy

//--- Prop Firm Protection Settings
input group "=== Prop Firm Protection Settings ==="
input bool IsPropFirmMode = true;         // Prop firm challenge mode
input double MaxTotalDrawdown = 4.5;      // Maximum total drawdown (%)
input double MaxDailyDrawdown = 2.5;      // Maximum daily drawdown (%)
input double DailyProfitTarget = 1.5;     // Daily profit target (%)
input double WeeklyProfitTarget = 3.0;    // Weekly profit target (%)
input int ConsecutiveLossLimit = 3;       // Max consecutive losses
input double AbsoluteMaxSLPips = 30.0;    // Maximum SL distance (pips)
input double MaxRiskPercent = 1.5;        // Maximum risk per trade (%)
input bool AvoidHighVolatilityTimes = true; // Avoid trading during high volatility times

//--- Hurst Analysis Settings
input group "=== Hurst Analysis Settings ==="
input bool UseAdvancedHurst = true;       // Use advanced Hurst analysis
input double HurstTrendThreshold = 0.53;  // Hurst trend threshold (>0.5)
input double HurstMeanRevThreshold = 0.47; // Hurst mean-reversion threshold (<0.5)
input int HurstPeriod = 300;              // Hurst calculation period
input bool AdaptiveHurstThresholds = true; // Auto-adjust Hurst thresholds
input int HurstMinReliability = 70;       // Minimum Hurst reliability (%)
input double HurstSensitivity = 1.2;      // Hurst sensitivity (>1 = more sensitive)

//--- Multi-timeframe Hurst Analysis
input group "=== Multi-timeframe Hurst Settings ==="
input bool UseMultiTimeframeHurst = true; // Use multi-timeframe Hurst
input int ShortTermHurstBars = 250;       // Short-term Hurst bars (entry)
input int MediumTermHurstBars = 500;      // Medium-term Hurst bars (swings)
input int LongTermHurstBars = 1000;       // Long-term Hurst bars (regime)
input bool UseHurstDivergence = true;     // Detect Hurst divergence
input double HurstDivergenceThreshold = 0.15; // Min divergence threshold
input bool AdjustTradesByHurstRegime = true; // Adjust trading by Hurst regime

//--- Moving Average Settings
input group "=== Moving Average Settings ==="
input int EmaScalpPeriod = 8;             // Ultra-fast EMA period
input int EmaFastPeriod = 21;             // Fast EMA period
input int EmaMediumPeriod = 89;           // Medium EMA period
input int EmaLongPeriod = 200;            // Long EMA period
input bool UseEMACrossover = true;        // Use EMA crossover signals

//--- Oscillator Settings
input group "=== Oscillator Settings ==="
input bool UseMACDDivergence = true;      // Use MACD divergence
input int MACDFast = 12;                  // MACD Fast period
input int MACDSlow = 26;                  // MACD Slow period
input int MACDSignalPeriod = 9;           // MACD Signal period
input int StochK = 5;                     // Stochastic %K
input int StochD = 3;                     // Stochastic %D
input int StochSlowing = 3;               // Stochastic slowing
input double StochUpperLevel = 75;        // Stochastic upper level
input double StochLowerLevel = 25;        // Stochastic lower level
input int RSIPeriod = 14;                 // RSI period
input double RSIOverbought = 65;          // RSI overbought level
input double RSIOversold = 35;            // RSI oversold level
input int ADXPeriod = 14;                 // ADX period
input double ADXThreshold = 18;           // ADX trend threshold
input int BollPeriod = 20;                // Bollinger Bands period
input double BollDeviation = 2.0;         // Bollinger Bands deviation

//--- Stop Loss & Take Profit Settings
input group "=== SL/TP Settings ==="
input ENUM_SL_TYPE SLType = SL_TYPE_COMBINED; // Stop Loss method
input double ATRMultiplierSL = 1.5;       // ATR multiplier for SL
input double MinSLPips = 15.0;            // Minimum SL distance (pips)
input double MaxSLPips = 45.0;            // Maximum SL distance (pips)
input double TPRatio = 1.8;               // TP:SL ratio
input double MinRiskRewardRatio = 1.5;    // Minimum risk:reward ratio
input double ScalperTPPips = 12.0;        // Minimum TP distance (pips)
input double MinLotSize = 0.01;           // Minimum lot size
input int ATRPeriod = 14;                 // ATR period

//--- Partial Position Management
input group "=== Partial Close Settings ==="
input bool UsePartialClose = true;        // Use partial position close
input double PartialClosePercent = 50.0;  // Percentage to close (%)
input double PartialCloseProfitPips = 8.0; // Activate at profit (pips)
input bool UseMultiLevelTP = true;        // Use multi-level take profit
input double TPLevel1Percent = 30.0;      // Level 1: % of position size
input double TPLevel1Ratio = 1.0;         // Level 1: ratio of SL distance

//--- Trailing Stop Settings
input group "=== Trailing Stop Settings ==="
input bool UseTrailingStop = true;        // Use trailing stop
input ENUM_TRAILING_TYPE TrailingType = TRAILING_TYPE_ADAPTIVE; // Trailing stop type
input double TrailingActivationPips = 10.0; // Activation threshold (pips)
input double TrailingATRMultiplier = 0.8; // ATR multiplier for trailing
input double TrailingPercentage = 80.0;   // Keep % of profit
input double TrailingStopPips = 8.0;      // Fixed trailing distance (pips)
input bool AdaptiveTrailing = true;       // Auto-adjust trailing method
input bool FastExitEMA = true;            // Fast exit on EMA cross

//--- Market Filters
input group "=== Market Filters ==="
input bool UseMarketHoursFilter = true;   // Use market hours filter
input int MarketHourStart = 7;            // Trading hours start (GMT)
input int MarketHourEnd = 21;             // Trading hours end (GMT)
input bool UseVolatilityFilter = true;    // Filter by market volatility
input double MinATRPips = 5.0;            // Minimum ATR required (pips)
input bool RestrictHighVolatility = true; // Avoid excessive volatility
input double VolatilityThresholdMult = 1.6; // High volatility threshold
input bool UseVolatilityBasedRisk = true; // Adjust risk based on volatility
input double VolatilityAdjustmentFactor = 0.7; // Volatility adjustment factor
input double MaxATRForNormalTrading = 15.0; // Max ATR for normal trading (pips)

//--- News Filter
input group "=== News Filter ==="
input bool UseNewsFilter = true;          // Avoid trading during news
input int MinutesBeforeNews = 60;         // Minutes to avoid before news
input int MinutesAfterNews = 30;          // Minutes to wait after news
input bool HighImpactOnly = true;         // Filter only high impact news
input int SignalChangeMinutes = 15;       // Min time between signal changes

//--- Interface Settings
input group "=== Dashboard Settings ==="
input bool ShowDashboard = true;          // Show dashboard
input int DashboardX = 20;                // Dashboard X position
input int DashboardY = 20;                // Dashboard Y position
input color PanelColor = C'25,25,25';     // Panel background color
input color TextColor = clrWhite;         // Text color
input color ValueColorBad = clrCrimson;   // Negative value color
input color ValueColorNeutral = clrGold;  // Neutral value color
input color ValueColorGood = clrLimeGreen; // Positive value color
input string FontName = "Consolas";       // Font name
input int FontSize = 10;                  // Font size
input int UpdateFrequency = 1;            // Update frequency (seconds)

//--- Expert Magic Number
input int ExpertMagic = 12345;            // Magic number for orders

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+

// Module objects
CHurstAnalysis *g_hurstAnalysis = NULL;         // Hurst analysis engine
CMarketStructure *g_marketStructure = NULL;     // Market structure analyzer
CSignalGenerator *g_signalGenerator = NULL;     // Signal generator
CPositionManager *g_positionManager = NULL;     // Position manager
CRiskManager *g_riskManager = NULL;             // Risk manager

// News events array
NewsEvent g_newsEvents[];

// Trading control
bool g_tradingEnabled = true;
bool g_tradePermit = true;
datetime g_lastUpdateTime = 0;
datetime g_lastNewsCheck = 0;
double g_currentATR = 0;
int g_gmtOffset = 0;

// Multi-timeframe Hurst Analysis
double g_shortTermHurst = 0.5;           // Short-term Hurst (entry timing)
double g_mediumTermHurst = 0.5;          // Medium-term Hurst (swing cycles)
double g_longTermHurst = 0.5;            // Long-term Hurst (market regime)
bool g_hurstDivergenceBullish = false;   // Bullish Hurst divergence detected
bool g_hurstDivergenceBearish = false;   // Bearish Hurst divergence detected
bool g_hurstAlignedTrending = false;     // Hurst values aligned for trend
bool g_hurstAlignedReverting = false;    // Hurst values aligned for mean reversion
double g_regimeChangeProbability = 0.0;  // Probability of regime change (0-1)

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit() {
   // Display EA info
   Print("Initializing Hurst Advanced Suite v3.50");
   
   // Get GMT offset
   g_gmtOffset = GetGMTOffset();
   Print("GMT Offset: ", g_gmtOffset, " minutes");
   
   // Initialize modules
   InitializeHurstAnalysis();
   InitializeMarketStructure();
   InitializeSignalGenerator();
   InitializePositionManager();
   InitializeRiskManager();
   
   // Load news data if using news filter
   if(UseNewsFilter) {
      LoadEconomicCalendar(g_newsEvents);
      g_lastNewsCheck = TimeCurrent();
   }
   
   // Create dashboard
   if(ShowDashboard) {
      DrawDashboardPanel(DashboardX, DashboardY, 250, 200, PanelColor);
      UpdateDashboard();
   }
   
   // Set up timer for dashboard updates
   EventSetTimer(UpdateFrequency);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // Clean up dashboard objects
   if(ShowDashboard) {
      CleanupDashboard();
   }
   
   // Delete timer
   EventKillTimer();
   
   // Clean up module objects
   if(g_hurstAnalysis != NULL) {
      delete g_hurstAnalysis;
      g_hurstAnalysis = NULL;
   }
   
   if(g_marketStructure != NULL) {
      delete g_marketStructure;
      g_marketStructure = NULL;
   }
   
   if(g_signalGenerator != NULL) {
      delete g_signalGenerator;
      g_signalGenerator = NULL;
   }
   
   if(g_positionManager != NULL) {
      delete g_positionManager;
      g_positionManager = NULL;
   }
   
   if(g_riskManager != NULL) {
      delete g_riskManager;
      g_riskManager = NULL;
   }
   
   Print("Hurst Advanced Suite deinitialized. Reason code: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
   // Check if trading is allowed
   if(!g_tradingEnabled) {
      return;
   }
   
   // Update market data
   UpdateMarketData();
   
   // Check trading conditions
   if(!CheckTradingConditions()) {
      return;
   }
   
   // Update position management
   if(g_positionManager != NULL) {
      g_positionManager.UpdatePositions();
   }
   
   // Check for new signals
   CheckForTradingSignals();
}

//+------------------------------------------------------------------+
//| Timer function                                                    |
//+------------------------------------------------------------------+
void OnTimer() {
   // Update dashboard
   if(ShowDashboard) {
      UpdateDashboard();
   }
   
   // Refresh news data periodically
   if(UseNewsFilter) {
      datetime currentTime = TimeCurrent();
      if(currentTime - g_lastNewsCheck > 3600) { // Refresh every hour
         LoadEconomicCalendar(g_newsEvents);
         g_lastNewsCheck = currentTime;
      }
   }
}

//+------------------------------------------------------------------+
//| Initialize Hurst Analysis module                                  |
//+------------------------------------------------------------------+
void InitializeHurstAnalysis() {
   if(g_hurstAnalysis != NULL) {
      delete g_hurstAnalysis;
   }
   
   g_hurstAnalysis = new CHurstAnalysis(
      HurstPeriod,
      HurstTrendThreshold,
      HurstMeanRevThreshold,
      AdaptiveHurstThresholds,
      HurstMinReliability,
      HurstSensitivity
   );
   
   if(g_hurstAnalysis == NULL) {
      Print("Failed to initialize Hurst Analysis module");
      g_tradingEnabled = false;
      return;
   }
   
   // Set parameters for multi-timeframe Hurst
   if(UseMultiTimeframeHurst) {
      Print("Enabling multi-timeframe Hurst analysis");
      
      // Update initial multi-timeframe Hurst values
      bool success = g_hurstAnalysis.CalculateMultiTimeframe(
         Symbol(), 
         g_shortTermHurst, 
         g_mediumTermHurst, 
         g_longTermHurst
      );
      
      if(success) {
         Print("Initial multi-timeframe Hurst values calculated: Short=", 
               DoubleToString(g_shortTermHurst, 3), 
               ", Medium=", DoubleToString(g_mediumTermHurst, 3), 
               ", Long=", DoubleToString(g_longTermHurst, 3));
         
         // Check for initial Hurst alignment
         bool isTrending = false;
         bool isMeanReverting = false;
         g_hurstAnalysis.IsHurstAligned(Symbol(), Period(), isTrending, isMeanReverting);
         
         g_hurstAlignedTrending = isTrending;
         g_hurstAlignedReverting = isMeanReverting;
         
         if(g_hurstAlignedTrending) {
            Print("Hurst values aligned for trending market");
         }
         else if(g_hurstAlignedReverting) {
            Print("Hurst values aligned for mean-reverting market");
         }
         
         // Check for Hurst divergence if enabled
         if(UseHurstDivergence) {
            bool isBullish = false;
            if(g_hurstAnalysis.DetectHurstDivergence(Symbol(), Period(), isBullish)) {
               g_hurstDivergenceBullish = isBullish;
               g_hurstDivergenceBearish = !isBullish;
               Print("Initial Hurst divergence detected: ", isBullish ? "Bullish" : "Bearish");
            }
         }
         
         // Calculate regime change probability
         g_regimeChangeProbability = g_hurstAnalysis.GetRegimeChangeProbability(Symbol(), Period());
         Print("Initial regime change probability: ", DoubleToString(g_regimeChangeProbability * 100, 1), "%");
      }
      else {
         Print("Warning: Failed to calculate initial multi-timeframe Hurst values");
      }
   }
}

//+------------------------------------------------------------------+
//| Initialize Market Structure module                                |
//+------------------------------------------------------------------+
void InitializeMarketStructure() {
   if(g_marketStructure != NULL) {
      delete g_marketStructure;
   }
   
   g_marketStructure = new CMarketStructure(
      Symbol(),
      Period(),
      RSIPeriod,
      ADXPeriod,
      ADXThreshold,
      StochK,
      StochD,
      StochSlowing,
      StochUpperLevel,
      StochLowerLevel,
      EmaFastPeriod,
      EmaMediumPeriod,
      EmaLongPeriod,
      BollPeriod,
      BollDeviation,
      ATRPeriod,
      VolatilityThresholdMult,
      MaxATRForNormalTrading,
      RSIOverbought,
      RSIOversold
   );
   
   if(g_marketStructure == NULL) {
      Print("Failed to initialize Market Structure module");
      g_tradingEnabled = false;
      return;
   }
   
   // Link Market Structure to Hurst Analysis
   if(g_hurstAnalysis != NULL && UseAdvancedHurst) {
      // Initialize with basic Hurst settings
      g_marketStructure.InitializeHurstAnalysis(
         HurstPeriod,
         HurstTrendThreshold,
         HurstMeanRevThreshold
      );
      
      // Set up pattern recognition sensitivity (higher with Hurst)
      if(UseMultiTimeframeHurst) {
         // Set higher sensitivity for pattern recognition if we're using multi-timeframe Hurst
         int candleSensitivity = 7;    // Medium-high sensitivity
         int harmonicSensitivity = 6;  // Medium sensitivity
         int wyckoffSensitivity = 7;   // Medium-high sensitivity
         
         g_marketStructure.SetPatternSensitivity(
            candleSensitivity,
            harmonicSensitivity,
            wyckoffSensitivity
         );
         
         Print("Enhanced pattern recognition sensitivity set with multi-timeframe Hurst");
      }
   }
}

//+------------------------------------------------------------------+
//| Initialize Signal Generator module                                |
//+------------------------------------------------------------------+
void InitializeSignalGenerator() {
   if(g_signalGenerator != NULL) {
      delete g_signalGenerator;
   }
   
   if(g_marketStructure == NULL) {
      Print("Cannot initialize Signal Generator: Market Structure module not available");
      g_tradingEnabled = false;
      return;
   }
   
   g_signalGenerator = new CSignalGenerator(
      Symbol(),
      Period(),
      g_marketStructure,
      ScalpingMode,
      UseMACDDivergence,
      UseEMACrossover,
      MACDFast,
      MACDSlow,
      MACDSignalPeriod,
      StochK,
      StochD,
      StochSlowing,
      StochUpperLevel,
      StochLowerLevel,
      EmaScalpPeriod,
      EmaFastPeriod,
      EmaMediumPeriod,
      EmaLongPeriod,
      SignalChangeMinutes
   );
   
   if(g_signalGenerator == NULL) {
      Print("Failed to initialize Signal Generator module");
      g_tradingEnabled = false;
   }
}

//+------------------------------------------------------------------+
//| Initialize Position Manager module                                |
//+------------------------------------------------------------------+
void InitializePositionManager() {
   if(g_positionManager != NULL) {
      delete g_positionManager;
   }
   
   g_positionManager = new CPositionManager(
      Symbol(),
      ExpertMagic,
      UseTrailingStop,
      TrailingActivationPips,
      TrailingStopPips,
      TrailingType,
      TrailingATRMultiplier,
      TrailingPercentage,
      true, // Use break-even
      TrailingActivationPips * 0.7, // Break-even trigger
      1.0, // Break-even extra pips
      UsePartialClose,
      PartialCloseProfitPips,
      PartialClosePercent,
      UseMultiLevelTP,
      TPLevel1Percent,
      TPLevel1Ratio,
      0 // Max holding time hours (0 = no limit)
   );
   
   if(g_positionManager == NULL) {
      Print("Failed to initialize Position Manager module");
      g_tradingEnabled = false;
   }
}

//+------------------------------------------------------------------+
//| Initialize Risk Manager module                                    |
//+------------------------------------------------------------------+
void InitializeRiskManager() {
   if(g_riskManager != NULL) {
      delete g_riskManager;
   }
   
   g_riskManager = new CRiskManager(
      Symbol(),
      RiskProfile,
      BaseRiskPercent,
      MaxRiskPercent,
      MinRiskRewardRatio,
      MaxTotalDrawdown,
      MaxDailyDrawdown,
      UseDynamicRiskControl,
      IsPropFirmMode,
      ConsecutiveLossLimit,
      VolatilityAdjustmentFactor,
      MinLotSize
   );
   
   if(g_riskManager == NULL) {
      Print("Failed to initialize Risk Manager module");
      g_tradingEnabled = false;
   }
}

//+------------------------------------------------------------------+
//| Update market data and indicators                                |
//+------------------------------------------------------------------+
void UpdateMarketData() {
   // Update ATR for risk management
   // Sửa cách gọi hàm indicator trong MT5
   int atrHandle = iATR(Symbol(), Period(), ATRPeriod);
   if(atrHandle != INVALID_HANDLE) {
      double atrBuffer[];
      if(CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) > 0) {
         g_currentATR = atrBuffer[0];
      }
      IndicatorRelease(atrHandle);
   }
   
   // Set ATR value in risk manager
   if(g_riskManager != NULL) {
      g_riskManager.SetATR(g_currentATR);
   }
   
   // Update Market Structure module
   if(g_marketStructure != NULL) {
      g_marketStructure.UpdateIndicators();
   }
   
   // Update multi-timeframe Hurst analysis
   if(UseMultiTimeframeHurst && g_hurstAnalysis != NULL) {
      // Update Hurst values
      bool success = g_hurstAnalysis.CalculateMultiTimeframe(
         Symbol(), 
         g_shortTermHurst, 
         g_mediumTermHurst, 
         g_longTermHurst
      );
      
      if(success) {
         // Check for Hurst alignment
         bool isTrending = false;
         bool isMeanReverting = false;
         g_hurstAnalysis.IsHurstAligned(Symbol(), Period(), isTrending, isMeanReverting);
         g_hurstAlignedTrending = isTrending;
         g_hurstAlignedReverting = isMeanReverting;
         
         // Check for Hurst divergence if enabled
         if(UseHurstDivergence) {
            bool isBullish = false;
            if(g_hurstAnalysis.DetectHurstDivergence(Symbol(), Period(), isBullish)) {
               g_hurstDivergenceBullish = isBullish;
               g_hurstDivergenceBearish = !isBullish;
            } else {
               g_hurstDivergenceBullish = false;
               g_hurstDivergenceBearish = false;
            }
         }
         
         // Update regime change probability
         g_regimeChangeProbability = g_hurstAnalysis.GetRegimeChangeProbability(Symbol(), Period());
      }
   }
   
   // Update account statistics
   if(g_riskManager != NULL) {
      g_riskManager.Update();
   }
   
   // Update last update time
   g_lastUpdateTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Check if trading is allowed based on various filters              |
//+------------------------------------------------------------------+
bool CheckTradingConditions() {
   datetime currentTime = TimeCurrent();
   
   // Check if trading is paused by risk manager
   if(g_riskManager != NULL && !g_riskManager.IsTradingAllowed()) {
      return false;
   }
   
   // Check trading hours
   if(UseMarketHoursFilter) {
      if(!IsWithinTradingHours(g_gmtOffset / 60, MarketHourStart, MarketHourEnd)) {
         return false;
      }
   }
   
   // Check news filter
   if(UseNewsFilter) {
      if(IsHighImpactNewsTime(currentTime, MinutesBeforeNews, MinutesAfterNews, g_newsEvents)) {
         return false;
      }
   }
   
   // Check volatility filter
   if(UseVolatilityFilter) {
      // Minimum volatility check
      if(g_currentATR < PipsToPrice(Symbol(), MinATRPips)) {
         return false;
      }
      
      // High volatility restriction
      if(RestrictHighVolatility && g_marketStructure != NULL && g_marketStructure.IsHighVolatility()) {
         return false;
      }
   }
   
   // Apply Hurst-based trading rules if enabled
   if(UseMultiTimeframeHurst && AdjustTradesByHurstRegime) {
      // High probability of regime change - reduce trading or pause
      if(g_regimeChangeProbability > 0.7) {
         Print("High regime change probability (", DoubleToString(g_regimeChangeProbability * 100, 1), 
               "%) - Trading conditions not optimal");
         return false;
      }
      
      // Special rules for aligned Hurst values
      if(g_hurstAlignedTrending) {
         // In strongly trending markets, we may adjust our trading conditions
         // For example, allow trading only in trend direction
         
         // For now, we'll just log this condition
         Print("Hurst aligned for trending - trading allowed with trend signals");
      }
      else if(g_hurstAlignedReverting) {
         // In strongly mean-reverting markets, we may adjust our conditions differently
         
         // For now, we'll just log this condition
         Print("Hurst aligned for mean-reversion - trading allowed for counter-trend signals");
      }
      
      // Check for divergences - could be early warning signals
      if(g_hurstDivergenceBullish) {
         Print("Bullish Hurst divergence - bullish signals favored");
      }
      else if(g_hurstDivergenceBearish) {
         Print("Bearish Hurst divergence - bearish signals favored");
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check for trading signals and execute trades                      |
//+------------------------------------------------------------------+
void CheckForTradingSignals() {
   // Ensure we have all required modules
   if(g_signalGenerator == NULL || g_riskManager == NULL || g_positionManager == NULL) {
      return;
   }
   
   // Check for trading signals
   SignalInfo signal = g_signalGenerator.CheckForSignals();
   
   // If valid signal found, process it
   if(signal.valid) {
      ExecuteTradeSignal(signal);
   }
}

//+------------------------------------------------------------------+
//| Execute trade based on signal                                     |
//+------------------------------------------------------------------+
void ExecuteTradeSignal(const SignalInfo &signal) {
   // Get current prices
   double price = (signal.direction == 1) ? SymbolInfoDouble(Symbol(), SYMBOL_ASK) : SymbolInfoDouble(Symbol(), SYMBOL_BID);
   
   // Apply multi-timeframe Hurst adjustments if enabled
   bool adjustmentApplied = false;
   double riskAdjustment = 1.0;  // Default - no adjustment
   
   if(UseMultiTimeframeHurst && AdjustTradesByHurstRegime) {
      // Check if signal direction matches Hurst alignment
      bool signalMatchesHurst = false;
      
      if(g_hurstAlignedTrending) {
         // For trending markets, check if signal follows trend
         if((signal.direction == 1 && g_longTermHurst > 0.55) || 
            (signal.direction == -1 && g_longTermHurst > 0.55)) {
            // Signal follows expected trend direction
            signalMatchesHurst = true;
            riskAdjustment = 1.2;  // Increase risk slightly for trend-following signals
            Print("Hurst Adjustment: Increased risk for trend-following signal");
            adjustmentApplied = true;
         }
      }
      else if(g_hurstAlignedReverting) {
         // For mean-reverting markets, check if signal is counter-trend
         if((signal.direction == 1 && g_marketStructure.GetMarketStructure() == MARKET_WEAK_DOWNTREND) || 
            (signal.direction == -1 && g_marketStructure.GetMarketStructure() == MARKET_WEAK_UPTREND)) {
            // Signal is counter-trend, which is good in mean-reverting markets
            signalMatchesHurst = true;
            riskAdjustment = 1.1;  // Slightly increase risk for counter-trend in mean-reverting markets
            Print("Hurst Adjustment: Increased risk for counter-trend signal in mean-reverting market");
            adjustmentApplied = true;
         }
      }
      
      // Check Hurst divergence - potential early signals
      if(signal.direction == 1 && g_hurstDivergenceBullish) {
         riskAdjustment = MathMax(riskAdjustment, 1.15);  // Increase risk for bullish signals with bullish divergence
         Print("Hurst Adjustment: Increased risk due to bullish Hurst divergence");
         adjustmentApplied = true;
      }
      else if(signal.direction == -1 && g_hurstDivergenceBearish) {
         riskAdjustment = MathMax(riskAdjustment, 1.15);  // Increase risk for bearish signals with bearish divergence
         Print("Hurst Adjustment: Increased risk due to bearish Hurst divergence");
         adjustmentApplied = true;
      }
      
      // Reduce risk when regime change is likely
      if(g_regimeChangeProbability > 0.5) {
         // Apply a linear reduction based on probability
         double reductionFactor = 1.0 - ((g_regimeChangeProbability - 0.5) * 0.8);
         riskAdjustment *= reductionFactor;
         Print("Hurst Adjustment: Reduced risk due to high regime change probability (", 
               DoubleToString(g_regimeChangeProbability * 100, 1), "%)");
         adjustmentApplied = true;
      }
   }
   
   // Calculate stop loss level
   double stopLoss = CalculateStopLoss(signal.direction, price);
   if(stopLoss <= 0) {
      Print("Invalid stop loss calculation. Trade aborted.");
      return;
   }
   
   // Calculate take profit level
   double takeProfit = CalculateTakeProfit(signal.direction, price, stopLoss);
   
   // Calculate position size
   double volume = g_riskManager.CalculateLotSize(price, stopLoss);
   
   // Apply risk adjustment from Hurst analysis
   if(adjustmentApplied) {
      volume *= riskAdjustment;
      
      // Ensure volume is within allowed range
      double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
      double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
      
      // Normalize to lot step
      volume = MathFloor(volume / lotStep) * lotStep;
      
      // Apply min/max constraints
      volume = MathMax(minLot, MathMin(maxLot, volume));
      
      Print("Final adjusted volume: ", DoubleToString(volume, 2), " (adjustment factor: ", DoubleToString(riskAdjustment, 2), ")");
   }
   
   if(volume <= 0) {
      Print("Invalid lot size calculation. Trade aborted.");
      return;
   }
   
   // Check if order can be opened with these parameters
   if(!g_riskManager.CanOpenOrder(signal.direction == 1 ? 0 : 1, price, stopLoss, volume)) {
      Print("Risk limits exceeded. Trade aborted.");
      return;
   }
   
   // Execute the trade
   string comment = "Hurst Suite: " + signal.description;
   
   // Add Hurst information to comment if using multi-timeframe Hurst
   if(UseMultiTimeframeHurst) {
      comment += " MTF-H(" + 
                DoubleToString(g_shortTermHurst, 2) + "/" + 
                DoubleToString(g_mediumTermHurst, 2) + "/" + 
                DoubleToString(g_longTermHurst, 2) + ")";
   }
   
   if(g_positionManager.OpenPosition(
      signal.direction == 1 ? 0 : 1,  // Convert direction to order type
      volume,
      stopLoss,
      takeProfit,
      comment,
      signal.marketStructure,
      g_marketStructure.GetHurstInfo().value
   )) {
      Print("Trade executed: ", comment, " at price ", price, 
           ", SL: ", stopLoss, ", TP: ", takeProfit, ", Volume: ", volume);
   } else {
      Print("Trade execution failed");
   }
}

//+------------------------------------------------------------------+
//| Calculate stop loss level                                         |
//+------------------------------------------------------------------+
double CalculateStopLoss(int direction, double entryPrice) {
   // Calculate stop loss based on inputs and market conditions
   double slDistance = 0;
   
   // Use RiskManager to calculate SL level
   if(g_riskManager != NULL) {
      int orderType = (direction == 1) ? 0 : 1; // Convert to OrderType (0=buy, 1=sell)
      
      return g_riskManager.CalculateStopLoss(
         orderType,
         entryPrice,
         SLType,
         g_currentATR,
         MinSLPips,
         MaxSLPips
      );
   }
   
   // Fallback calculation if RiskManager not available
   slDistance = ATRMultiplierSL * g_currentATR;
   
   // Apply minimum and maximum SL distance
   double minSL = PipsToPrice(Symbol(), MinSLPips);
   double maxSL = PipsToPrice(Symbol(), MaxSLPips);
   
   slDistance = MathMax(slDistance, minSL);
   slDistance = MathMin(slDistance, maxSL);
   
   // Calculate SL price based on direction
   return (direction == 1) ? entryPrice - slDistance : entryPrice + slDistance;
}

//+------------------------------------------------------------------+
//| Calculate take profit level                                       |
//+------------------------------------------------------------------+
double CalculateTakeProfit(int direction, double entryPrice, double stopLossPrice) {
   // Calculate take profit based on inputs and market conditions
   
   // Use RiskManager to calculate TP level
   if(g_riskManager != NULL) {
      int orderType = (direction == 1) ? 0 : 1; // Convert to OrderType (0=buy, 1=sell)
      
      return g_riskManager.CalculateTakeProfit(
         orderType,
         entryPrice,
         stopLossPrice,
         TPRatio
      );
   }
   
   // Fallback calculation if RiskManager not available
   double slDistance = MathAbs(entryPrice - stopLossPrice);
   double tpDistance = slDistance * TPRatio;
   
   // Minimum TP distance check
   double minTP = PipsToPrice(Symbol(), ScalperTPPips);
   tpDistance = MathMax(tpDistance, minTP);
   
   // Calculate TP price based on direction
   return (direction == 1) ? entryPrice + tpDistance : entryPrice - tpDistance;
}

//+------------------------------------------------------------------+
//| Update dashboard information                                      |
//+------------------------------------------------------------------+
void UpdateDashboard() {
   if(!ShowDashboard || g_riskManager == NULL) return;
   
   // Create extended dashboard for multi-timeframe Hurst if enabled
   if(UseMultiTimeframeHurst) {
      // Draw larger dashboard panel
      DrawDashboardPanel(DashboardX, DashboardY, 250, 300, PanelColor);
      
      // Get values for dashboard
      double equity = g_riskManager.GetCurrentEquity();
      double balance = g_riskManager.GetCurrentBalance();
      double dailyPL = g_riskManager.GetDailyProfitLoss();
      double weeklyPL = g_riskManager.GetWeeklyProfitLoss();
      
      string marketState = "Unknown";
      double hurstValue = 0.5;
      
      if(g_marketStructure != NULL) {
         ENUM_MARKET_STRUCTURE structure = g_marketStructure.GetMarketStructure();
         marketState = MarketStructureToString(structure);
         hurstValue = g_marketStructure.GetHurstInfo().value;
      }
      
      int positionCount = 0;
      double totalProfit = 0;
      
      if(g_positionManager != NULL) {
         positionCount = g_positionManager.GetPositionCount();
         totalProfit = g_positionManager.GetTotalProfit();
      }
      
      // Determine colors for the Hurst values
      color shortColor = GetHurstColor(g_shortTermHurst);
      color mediumColor = GetHurstColor(g_mediumTermHurst);
      color longColor = GetHurstColor(g_longTermHurst);
      
      // Update standard dashboard
      ::UpdateDashboard(
         equity,
         balance,
         dailyPL,
         weeklyPL,
         marketState,
         hurstValue,
         positionCount,
         totalProfit,
         TextColor,
         ValueColorGood,
         ValueColorBad,
         ValueColorNeutral
      );
      
      // Add multi-timeframe Hurst information
      AddDashboardLabel("lbl_mtf_hurst", "Multi-timeframe Hurst:", 25, 185, TextColor);
      
      AddDashboardLabel("lbl_short_hurst", "Short-term (entry):", 25, 205, TextColor);
      AddDashboardLabel("val_short_hurst", DoubleToString(g_shortTermHurst, 3), 120, 205, shortColor);
      
      AddDashboardLabel("lbl_medium_hurst", "Medium-term (swing):", 25, 225, TextColor);
      AddDashboardLabel("val_medium_hurst", DoubleToString(g_mediumTermHurst, 3), 120, 225, mediumColor);
      
      AddDashboardLabel("lbl_long_hurst", "Long-term (regime):", 25, 245, TextColor);
      AddDashboardLabel("val_long_hurst", DoubleToString(g_longTermHurst, 3), 120, 245, longColor);
      
      // Add regime change probability
      AddDashboardLabel("lbl_regime_prob", "Regime change prob:", 25, 265, TextColor);
      AddDashboardLabel("val_regime_prob", DoubleToString(g_regimeChangeProbability * 100, 1) + "%", 
                       120, 265, g_regimeChangeProbability > 0.5 ? ValueColorBad : ValueColorNeutral);
      
      // Add Hurst alignment status
      string alignmentStatus = "None";
      color alignmentColor = ValueColorNeutral;
      
      if(g_hurstAlignedTrending) {
         alignmentStatus = "Trending";
         alignmentColor = ValueColorGood;
      }
      else if(g_hurstAlignedReverting) {
         alignmentStatus = "Mean-Rev";
         alignmentColor = ValueColorBad;
      }
      
      AddDashboardLabel("lbl_alignment", "Hurst Alignment:", 25, 285, TextColor);
      AddDashboardLabel("val_alignment", alignmentStatus, 120, 285, alignmentColor);
   }
   else {
      // Standard dashboard
      // Get values for dashboard
      double equity = g_riskManager.GetCurrentEquity();
      double balance = g_riskManager.GetCurrentBalance();
      double dailyPL = g_riskManager.GetDailyProfitLoss();
      double weeklyPL = g_riskManager.GetWeeklyProfitLoss();
      
      string marketState = "Unknown";
      double hurstValue = 0.5;
      
      if(g_marketStructure != NULL) {
         ENUM_MARKET_STRUCTURE structure = g_marketStructure.GetMarketStructure();
         marketState = MarketStructureToString(structure);
         hurstValue = g_marketStructure.GetHurstInfo().value;
      }
      
      int positionCount = 0;
      double totalProfit = 0;
      
      if(g_positionManager != NULL) {
         positionCount = g_positionManager.GetPositionCount();
         totalProfit = g_positionManager.GetTotalProfit();
      }
      
      // Update standard dashboard
      ::UpdateDashboard(
         equity,
         balance,
         dailyPL,
         weeklyPL,
         marketState,
         hurstValue,
         positionCount,
         totalProfit,
         TextColor,
         ValueColorGood,
         ValueColorBad,
         ValueColorNeutral
      );
   }
}

//+------------------------------------------------------------------+
//| Get color for Hurst value display                                |
//+------------------------------------------------------------------+
color GetHurstColor(double hurstValue) {
   if(hurstValue > 0.60) return ValueColorGood;    // Strong trend
   if(hurstValue >= 0.55) return clrLightGreen;    // Moderate trend
   if(hurstValue > 0.52 && hurstValue < 0.55) return ValueColorNeutral; // Slight trend
   if(hurstValue >= 0.48 && hurstValue <= 0.52) return clrGold;    // Random walk
   if(hurstValue > 0.45 && hurstValue < 0.48) return ValueColorNeutral; // Slight mean-reversion
   if(hurstValue >= 0.40) return clrPink;         // Moderate mean-reversion
   return ValueColorBad;                           // Strong mean-reversion
}