### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ f9462748-2741-11eb-26a5-e3919e49a7ae
begin
	using Pkg
	Pkg.add(["CSV", "Underscores", "CategoricalArrays", "DataDeps", "ShiftedArrays", "RollingFunctions"])
	using CSV, DataFrames, Underscores, CategoricalArrays, DataDeps, ShiftedArrays, RollingFunctions
end

# ╔═╡ bf18e6c0-2749-11eb-15c7-cb7cdc32c6ce
using Dates

# ╔═╡ 5d94a42c-2742-11eb-1c7e-19178674181a
using AlgebraOfGraphics, CairoMakie, CairoMakie.AbstractPlotting.MakieLayout

# ╔═╡ c7f23ec2-2749-11eb-0a37-7393326e306d
#dates = Date(2020, 10, 10):Day(1):Date(2020, 11, 3)

# ╔═╡ ce05c0c6-274f-11eb-0a19-aff508912de9


# ╔═╡ fb641c96-2751-11eb-3436-a3b99254b813


# ╔═╡ e974b1c6-2749-11eb-0e65-4f60709842c4
date_str(date) = 
    "$(year(date))" *
    lpad("$(month(date))", 2, '0') *
	lpad("$(day(date))", 2, '0')

# ╔═╡ 7ba83d86-2740-11eb-01ed-eb8f73b282e8
md"# Covid data for Austria"

# ╔═╡ b37195c8-2740-11eb-2ea3-95cbedb4adfe
DATA_DIR = expanduser("~/Data/coronaDAT/archive")

# ╔═╡ c54b131e-274a-11eb-1f54-ab1d1147f2b8
path(date) = joinpath(DATA_DIR, date_str(date), "data")

# ╔═╡ f7c673c2-2740-11eb-0d1e-1b4eb8c2a9a1
function ZIP_PATH(date)
	cutoff = Date(2020,11,03)
	if date < cutoff
		zip_name = joinpath(path(date), date_str(date) * "_050200_orig_csv.zip")
	elseif date <= cutoff + Day(1)
		zip_name = joinpath(path(date), date_str(date) * "_140201_orig_csv.zip")
	elseif date in Date.(2020,11,[05,14])
		zip_name = joinpath(path(date), date_str(date) * "_140201_orig_csv_ages.zip")
	elseif date >= Date(2020,11,06)
		zip_name = joinpath(path(date), date_str(date) * "_140202_orig_csv_ages.zip")
	end
end

# ╔═╡ f68e6e0a-274a-11eb-1b9f-5d097bfdea15
function unzip(date)
	orig = ZIP_PATH(date)
	dest = path(date)
    run(`unzip -o $orig -d $(dest)/unzipped/`)
end
#DataDeps.unpack(joinpath(ZIP_PATH), keep_originals=true)

# ╔═╡ cf7317dc-2741-11eb-1aca-6fa89b33e7cb
FOLDER(date) = joinpath(path(date), "unzipped")

# ╔═╡ 29254230-275d-11eb-3841-a372cae03256
function group_provinces(bundesland)
	if bundesland in ["Wien", "Österreich"]
		bundesland
	elseif bundesland in ["Niederösterreich", "Burgenland"]
		"NÖ, Bgld"
	elseif bundesland in ["Steiermark", "Kärnten"]
		"Stmk, Ktn"
	else #if bundesland in ["Tirol", "Vorarlberg", "Salzburg"]
		"OÖ, Sbg, T, V"
	end
end

# ╔═╡ 026adc02-2752-11eb-3e3c-1fbd43cb22f1
dates = Date(2020,10,10):Day(1):Date(2020,11,14)

# ╔═╡ e27b837a-2749-11eb-05c9-cb299a613f53
date = dates[end]

# ╔═╡ b3ed1f96-2749-11eb-0ce9-7dd56e0d95d0
date_str(date)

# ╔═╡ 834df05a-274d-11eb-2852-d312a469b6e1
(path(date))

# ╔═╡ 09011a6c-274e-11eb-1b01-75615fb84b88
df000 = mapreduce(vcat, dates) do date
	unzip(date)
	df = CSV.File(joinpath(FOLDER(date), "CovidFaelle_Altersgruppe.csv")) |> DataFrame
	df[!,:date] .= date
	df
end

# ╔═╡ a883b7f0-275d-11eb-0023-135c3d3f8041
df00 = transform!(df000, :Bundesland => ByRow(group_provinces) => :region)

# ╔═╡ cccaf8f0-2742-11eb-2c67-e95c6a86227b
begin
	age_bins_ordered = [
		"<5", "5-14", "15-24", "25-34", "35-44", 
		"45-54", "55-64", "65-74", "75-84", ">84"
		]
	
	transform!(df00, "Altersgruppe" => (v -> categorical(v, levels = age_bins_ordered, ordered = true)) => "Altersgruppe")

end;


# ╔═╡ f9ab3190-2743-11eb-103f-090385344ec1
unique(df00.Altersgruppe)

# ╔═╡ 282102f8-2743-11eb-30cc-abfec6dbe839
begin
	cols_to_keep = ["Anzahl", "AnzahlGeheilt", "AnzahlTot"]	
	cols_to_sum = ["AnzEinwohner"; cols_to_keep]
end

# ╔═╡ bf2aa776-2743-11eb-1e81-35ebe74e1996
md"Getting rid of gender."

# ╔═╡ 1b7056fe-2742-11eb-1a78-b7a93986dde7
#df = filter(:date => ==(first(df00.date)), df00)

# ╔═╡ 23d9f45e-2746-11eb-18f8-effe5626e824
@_ df00 |>
    filter(:AnzEinwohner => ismissing, __) |>
    all(__.Geschlecht .== "U")

# ╔═╡ 3c67cdba-2747-11eb-3f44-1bd1227e146c
df0 = transform!(df00, :AnzEinwohner => ByRow(x -> coalesce(x, 0)) => :AnzEinwohner);

# ╔═╡ 5d33a77a-2743-11eb-2057-91521c94a644
df1 = @_ df0 |>
    #filter(:Bundesland => !=("Österreich"), __) |> 
	groupby(__, ["Altersgruppe", "region", "date"]) |>
    combine(__, cols_to_sum .=> sum .=> cols_to_sum) |>
	rename!(__, "AnzahlGeheilt" => "geheilt", "AnzahlTot" => "tot", "Anzahl" => "gesamt");


# ╔═╡ 52470e32-2744-11eb-2fc9-83509fb74ba4
df1[!,"aktiv"] = df1[!,"gesamt"] .- df1[!,"geheilt"] .- df1[!,"tot"];

# ╔═╡ b2bd0644-2745-11eb-3fe3-f1c5880aeae6
df2 = stack(df1, ["gesamt", "geheilt", "tot", "aktiv"], variable_name = "status")

# ╔═╡ e4a22a2a-2747-11eb-2b05-e739fb71d0d1
df3 = @_ df2 |>
    sort(__, :date) |> 
    groupby(__, [:region, :Altersgruppe, :status]) |>
	transform!(__, :value => (v -> runmean(v, 7)) => :value_smooth, ungroup=false) |>
	transform!(__, :value_smooth => (v -> [missing; diff(v)]) => :diff,
	               :value_smooth => (v -> [missing; diff(v)] ./ lag(v)) => :growth) |>
	transform!(__, [:value, :AnzEinwohner] => ByRow(/) => :relative) |>
    transform!(__, :date => ByRow(d -> (d - Date(2020, 01, 01)).value) => :dayofyear)

# ╔═╡ e43966ee-2755-11eb-12ed-d34e3e53049d
df2.date .- Date(2020, 01, 01) .|> x -> x.value

# ╔═╡ e2f9a320-2755-11eb-2b6d-7bdc218a9338
Date(2020, 11, 01) - Date(2020, 01, 01) |> typeof |>  fieldnames

# ╔═╡ 10b35578-2755-11eb-2ab4-f381425f7fcc
@_ df3 |>
    filter(:region => ==("Österreich"), __) |>
    filter(:Altersgruppe => ==("75-84"), __) |> 
    filter(:status => ==("aktiv"), __)

# ╔═╡ d6612efe-2759-11eb-000a-f5d78384f00a
begin
	df3[!,:relativ] = df3.value ./ (df3.AnzEinwohner ./ 1_000_000)
	
	df4 = @_ df3 |>
    	filter!(:diff => !ismissing, __) |>
    	transform!(__, [:growth, :diff] .=> disallowmissing .=> [:growth, :diff])	
end;

# ╔═╡ 69dfa04a-2753-11eb-2747-414c0aba03a7
let 
	aog = @_ df4 |>
		filter(:region => ==("Österreich"), __) |> 
    	filter(:status => ==("aktiv"), __) |>
    	data |>
    	__ * visual(Lines) * mapping(:dayofyear, :growth, color=:Altersgruppe,
	#layout_y = :Bundesland,
	#layout_y = Dims(1)
		) 
	
	scene, layout = layoutscene()
	AlgebraOfGraphics.layoutplot!(scene, layout, aog)
	
	ax1 = contents(layout)[1,1] |> contents 
	AbstractPlotting.MakieLayout.vlines!(ax1[1], [(Date(2020, 11, 03) - Date(2020, 01, 01)).value])
	scene
end

# ╔═╡ 27939628-275e-11eb-1388-891efec19abe
let 
	aog = @_ df4 |>
		filter(:region => !=("Österreich"), __) |> 
    	filter(:status => ==("aktiv"), __) |>
    	data |>
    	__ * visual(Lines) * mapping(:dayofyear, :growth, color=:Altersgruppe,
	         layout_y = :region
	#layout_y = Dims(1)
		) 
	
	scene, layout = layoutscene()
	AlgebraOfGraphics.layoutplot!(scene, layout, aog)
	
	ax1 = contents(layout)[1,1] |> contents 
	AbstractPlotting.MakieLayout.vlines!(ax1[1], [(Date(2020, 11, 03) - Date(2020, 01, 01)).value])
	scene
end

# ╔═╡ 244879a8-2758-11eb-21a8-cb0b9857e6e1
@_ df3 |>
	filter(:region => ==("Österreich"), __) |> 
    filter(:status => ==("aktiv"), __) |>
    data |>
    __ * visual(Lines) * mapping(:date, :relative, color=:Altersgruppe,
	#layout_y = :Bundesland,
	#layout_y = Dims(1)
	) |> draw

# ╔═╡ 6a86430c-2742-11eb-2ca1-e12edd4db644
@_ df2 |>
   filter(:region => !=("Österreich"), __) |> 
   filter(:date => ==(first(__.date)), __) |>
   data |>
   __ * visual(Lines) * mapping(:Altersgruppe, :relativ, color = :region, layout_y = :status) |> draw

# ╔═╡ Cell order:
# ╠═f9462748-2741-11eb-26a5-e3919e49a7ae
# ╠═bf18e6c0-2749-11eb-15c7-cb7cdc32c6ce
# ╠═c7f23ec2-2749-11eb-0a37-7393326e306d
# ╠═ce05c0c6-274f-11eb-0a19-aff508912de9
# ╠═fb641c96-2751-11eb-3436-a3b99254b813
# ╠═e27b837a-2749-11eb-05c9-cb299a613f53
# ╠═e974b1c6-2749-11eb-0e65-4f60709842c4
# ╠═b3ed1f96-2749-11eb-0ce9-7dd56e0d95d0
# ╠═7ba83d86-2740-11eb-01ed-eb8f73b282e8
# ╠═b37195c8-2740-11eb-2ea3-95cbedb4adfe
# ╠═c54b131e-274a-11eb-1f54-ab1d1147f2b8
# ╠═834df05a-274d-11eb-2852-d312a469b6e1
# ╠═f7c673c2-2740-11eb-0d1e-1b4eb8c2a9a1
# ╠═f68e6e0a-274a-11eb-1b9f-5d097bfdea15
# ╠═cf7317dc-2741-11eb-1aca-6fa89b33e7cb
# ╠═09011a6c-274e-11eb-1b01-75615fb84b88
# ╠═29254230-275d-11eb-3841-a372cae03256
# ╠═a883b7f0-275d-11eb-0023-135c3d3f8041
# ╠═026adc02-2752-11eb-3e3c-1fbd43cb22f1
# ╠═cccaf8f0-2742-11eb-2c67-e95c6a86227b
# ╠═f9ab3190-2743-11eb-103f-090385344ec1
# ╠═282102f8-2743-11eb-30cc-abfec6dbe839
# ╟─bf2aa776-2743-11eb-1e81-35ebe74e1996
# ╠═1b7056fe-2742-11eb-1a78-b7a93986dde7
# ╠═23d9f45e-2746-11eb-18f8-effe5626e824
# ╠═3c67cdba-2747-11eb-3f44-1bd1227e146c
# ╠═5d33a77a-2743-11eb-2057-91521c94a644
# ╠═52470e32-2744-11eb-2fc9-83509fb74ba4
# ╠═b2bd0644-2745-11eb-3fe3-f1c5880aeae6
# ╠═e4a22a2a-2747-11eb-2b05-e739fb71d0d1
# ╠═e43966ee-2755-11eb-12ed-d34e3e53049d
# ╠═e2f9a320-2755-11eb-2b6d-7bdc218a9338
# ╠═10b35578-2755-11eb-2ab4-f381425f7fcc
# ╠═d6612efe-2759-11eb-000a-f5d78384f00a
# ╠═5d94a42c-2742-11eb-1c7e-19178674181a
# ╠═69dfa04a-2753-11eb-2747-414c0aba03a7
# ╠═27939628-275e-11eb-1388-891efec19abe
# ╠═244879a8-2758-11eb-21a8-cb0b9857e6e1
# ╠═6a86430c-2742-11eb-2ca1-e12edd4db644
