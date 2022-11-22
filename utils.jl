using CSV
using DataFrames
using JLD2
using HTTP
using JSON3


const base_uniswap_fee = 0.003
const usdc_wad = 10^6
const weth_wad = 10^18

const dex_db_path = "/home/DefiClass2022/databases/dexes/"
const topic0_db = "/data/home/peter.kuchel/code/general_data/topic0s.json"

const Sync = "1C411E9A96E071241C2F21F7726B17AE89E3CAB4C78BE50E062B03A9FFFBBAD1"
const unisawp_v2 = "B4E16D0168E52D35CACD2C6185B44281EC28C9DC"


unpad_topic(topic::String) = replace(topic, topic_padding => "")

to_big_int(x::String) = parse(BigInt, x, base=16)

to_int(x::String) = parse(Int, x, base=16)

convert_string_to_date(x::String) = DateTime(x, "yyyy-mm-dd HH:MM:SS")

function get_topic0_db()
    local js_string = read(topic0_db, String)
    return JSON3.read(js_string, Dict)
end


const cols_to_remove = [
    :chain_id,
    :block_id
]

remove_testnets!(df::DataFrame) = df[in.(r"test", df[!, :chain_name]), !]

make_lean!(df::DataFrame) = select!(df, Not(cols_to_remove))

function get_liquidity_pools()
end

function get_all_dex_data()

    local files = readdir(dex_db_path)[1:end-1] # all except liquidity_pools.jl
    local df = load_object(dex_db_path * files[1])
    for f in files[2:end]

        local _df = load_object(dex_db_path * f)
        df = vcat(df, _df)

    end

    return df
end

function round_dateTime(a::DateTime)
    stringDate = Dates.format(round(a, Dates.Minute(1)), Dates.ISODateTimeFormat)
    stringDate = stringDate[begin:end-2]
    RoundedDate = Dates.DateTime(stringDate, "yyyy-mm-ddTHH:MM:SS")
    Rounded_plus_one_min = RoundedDate + Dates.Minute(1)
    return Rounded_plus_one_min
end

function offset_one(arr::Vector{DateTime})
    # Shifts a datetime column down 1 unit to match sync data.
    local offset_arr = Vector{Union{DateTime,Missing}}(undef, length(arr))

    for (i, a) in enumerate(arr[2:end])
        offset_arr[i+1] = round_dateTime(a)
    end

    offset_arr[1] = DateTime("2022-01-01T00:00:00")

    return offset_arr
end


# formula from the slides from class 
calc_swap_rate(amt1::BigFloat, amt2::BigFloat, tokens_to_swap::Float64) = (997 * tokens_to_swap * amt2) / (997 * tokens_to_swap + 1000 * amt1)

function SwapProfit(data0::BigFloat, data1::BigFloat, BinanceRate::Float64)
    SwapRate = (997*data0*0.001)/(997*0.001+1000*data1) * (1/0.001)
    profit::Float64 = 0
    Buy_ETH_and_Swap_it::Float64 = 0
    Buy_USDC_and_Swap_it::Float64 = 0

    if SwapRate > BinanceRate
        optimizedX = (10*sqrt(9970)*sqrt(data0*data1)-1000*data1*sqrt(BinanceRate))/(997*sqrt(BinanceRate))
        optimizedY = BinanceRate + ((997*data0*optimizedX)/(997*optimizedX+1000*data1) * (1/optimizedX)-BinanceRate) * optimizedX
        profit = (optimizedY-BinanceRate)*optimizedX
        Buy_ETH_and_Swap_it = optimizedX
    else
        data0Temp = data0
        data0 = data1
        data1 = data0Temp
        BinanceRate = 1/BinanceRate
        optimizedX = (10*sqrt(9970)*sqrt(data0*data1)-1000*data1*sqrt(BinanceRate))/(997*sqrt(BinanceRate))
        optimizedY = BinanceRate + ((997*data0*optimizedX)/(997*optimizedX+1000*data1) * (1/optimizedX)-BinanceRate) * optimizedX
        profit = (optimizedY-BinanceRate)*optimizedX
        profit = 0
        Buy_USDC_and_Swap_it = optimizedX
    end
    return (profit, Buy_ETH_and_Swap_it, Buy_USDC_and_Swap_it)
end



const cols_to_exclude = ["chain_id", "chain_name", "block_id", "block_hash", "block_parent_hash", "block_height", "block_miner", "block_mining_cost", "block_gas_limit", "block_gas_used", "successful", "tx_mining_cost", "tx_creates", "tx_value", "tx_gas_offered", "tx_gas_spent", "tx_gas_price", "log_emitter"]

# Loads checkmark instead of function when importing
println("Successfully loaded 'utils.jl'")