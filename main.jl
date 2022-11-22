# Required Packages
using Pkg;
using Binance, Dates, DataFrames, Plots

include("utils.jl")
include("dex_funcs.jl")
include("binance_functions.jl")
include("Plotting.jl")

StartDate = DateTime("2022-01-01T00:00:00")
EndDate = DateTime("2022-09-15T00:00:00")
##############################################################################################################
#############################################   Code for Main   ###############################################
##############################################################################################################

Dex_df = @time get_all_dex_data()

syncs_df = @time "getting the syncs data" get_sync_data(Dex_df)
ETHUSDC_df = @time "getting the ETHUSD prices from Binance api" get_ETHUSD_prices(StartDate, EndDate)
Uniswap_df = get_uniswap_df(syncs_df, ETHUSDC_df)
Uniswap_df_last_block_sync = filter_last_sync_in_block(Uniswap_df)
df = get_arbs(Uniswap_df_last_block_sync)


rownumber = 811
BinanceRate = df.Close[rownumber]
data0 = df.data0[rownumber]
data1 = df.data1[rownumber]
plot_arbitrage_oppotunity(data0, data1, BinanceRate)


Only_Eth_trades_df = df[(df.profits .!= 0), :]

new_array = Float64[]
cum_profit = 0
for (i, a) in enumerate(df.profits)
    cum_profit = a + cum_profit
    if a > 0
        push!(new_array, a)
    end
end
describe(new_array)
println(cum_profit)
# data0 = convert(BigFloat, 100)
# data1 = convert(BigFloat, 10)
# BinanceRate = convert(Float64, 7)
# plot_arbitrage_oppotunity(data0, data1, BinanceRate)



#############################################################################################################
#################################################   Other   #################################################
#############################################################################################################

Uniswap_with_live_prices[!, [:data0_real, :data1_real, :profits, :eth_vec, :usdc_vec]]
a = Uniswap_with_live_prices.data0_real[42]
b = Uniswap_with_live_prices.data1_real[42]
c = Uniswap_with_live_prices.CloseUSDC[42]
(profit, swap_for_eth, swap_for_usdc) = SwapProfit(a, b, c)

Uniswap_with_live_prices.eth_vec
describe(Uniswap_with_live_prices) |> println

Uniswap_with_live_prices.SwapRate[1]



# Sync = "1C411E9A96E071241C2F21F7726B17AE89E3CAB4C78BE50E062B03A9FFFBBAD1"
# Swap = "D78AD95FA46C994B6551D0DA85FC275FE613CE37657FB8D5E3D130840159D822"
# Burn = "DCCD412F0B1252819CB1FD330B93224CA42612892BB3F4F789976E6D81936496"
# Mint = "4C209B5FC8AD50758F13E2E1088BA56A560DFF690A1C6FEF26394F4C03821C4F" 
# Approval = "8C5BE1E5EBEC7D5BD14F71427D1E84F3DD0314C0F7B2291E5B200AC8C7C3B925"
# Transfer = "DDF252AD1BE2C89B69C2B068FC378DAA952BA7F163C4A11628F55A4DF523B3EF"
# SetOracle = "D3B5D1E0FFAEFF528910F3663F0ADACE7694AB8241D58E17A91351CED2E08031"
