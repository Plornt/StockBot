function plotMainGraph (elementID, series, options) {
	$.plot(elementID, [
		{ data: oilprices, label: "Oil price ($)" },
		{ data: exchangerates, label: "USD/EUR exchange rate", yaxis: 2 }
	], {
		xaxes: [ { mode: "time" } ],
		yaxes: [ { min: 0 }, {
			// align if we are to the right
			alignTicksWithAxis: position == "right" ? 1 : null,
			position: position,
			tickFormatter: euroFormatter
		} ],
		legend: { position: "sw" }
	});

}