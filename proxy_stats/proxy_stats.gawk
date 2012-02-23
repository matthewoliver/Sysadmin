BEGIN {
	badlines = 0
	numdenies = 0
	analysis_start = systime()
	firstreq = analysis_start
	lastreq = 0

	fastxfer = 3.0 * 1000
	totalstr = "All requests"
}
{
	if (NF == 9) {    # Squid 1.1 native log format
		timestamp = $1
		elapsed = $2
		client = $3
		if (split($4, codes, /\//) != 2) {
			badlines++
			next
		}
		local = codes[1]
		status = codes[2]
		size = $5
		method = $6
		url = $7
		ident = $8
		if (split($9, hier, /\//) != 2) {
			badlines++
			next
		}
		hierarchie = hier[1]
		neighbor = hier[2]
		objtype = ""
	} else if (NF == 10) {    # Squid 3.* native log format
		timestamp = $1
		elapsed = $2
		client = $3
		if (split($4, codes, /\//) != 2) {
			badlines++
			next
		}
		local = codes[1]
		status = codes[2]
		size = $5
		method = $6
		url = $7
		ident = $8
		if (split($9, hier, /\//) != 2) {
			badlines++
			next
		}
		hierarchie = hier[1]
		neighbor = hier[2]
		objtype = tolower($10)
	} else if (NF == 7) {    # Squid 1.0 native log format
		timestamp = $1
		elapsed = $2
		client = $3
		if (split($4, codes, /\//) != 3) {
			badlines++
			next
		}
		local = codes[1]
		status = codes[2]
		size = $5
		method = $6
		url = $7
		ident = "unknown"
		hierarchie = codes[3]
		neighbor = "unknown"
		objtype = ""
	} else {
		badlines++
		next
	}

	isdeny = (index(local, "DENIED") == 0) ? 0 : 1
	isxfer = (status < 400 && !isdeny && (substr(local, 1, 4) == "TCP_" || index(local, "UDP_HIT_OBJ") != 0)) ? 1 : 0
	ishit = (isxfer && hierarchie == "NONE") ? 1 : 0
	isfast = (isxfer && elapsed < fastxfer) ? 1 : 0
	xferbytes = isxfer ? size : 0
	xferthroughput = (elapsed > 0) ? (xferbytes / elapsed) : 0
	hitbytes = ishit ? size : 0
	if (timestamp < firstreq) firstreq = timestamp
	if (timestamp > lastreq) lastreq = timestamp
	weeknr = int(timestamp / 604800)
	if (!(weeknr in weekasc)) weekasc[weeknr] = strftime("%Y/%m/%d", weeknr * 604800)
	week = weekasc[weeknr]

	ltr[local] += 1
	lxr[local] += isxfer
	lxb[local] += xferbytes
	lxt[local] += xferthroughput
	lhr[local] += ishit
	lhb[local] += hitbytes

	str[status] += 1
	sxr[status] += isxfer
	sxb[status] += xferbytes
	sxt[status] += xferthroughput
	shr[status] += ishit
	shb[status] += hitbytes

	utr[ident] += 1
	uxr[ident] += isxfer
	uxb[ident] += xferbytes
	uxt[ident] += xferthroughput
	uhr[ident] += ishit
	uhb[ident] += hitbytes

	htr[hierarchie] += 1
	hxr[hierarchie] += isxfer
	hxb[hierarchie] += xferbytes
	hxt[hierarchie] += xferthroughput
	hhr[hierarchie] += ishit
	hhb[hierarchie] += hitbytes

	ttr[totalstr] += 1
	txr[totalstr] += isxfer
	txb[totalstr] += xferbytes
	txt[totalstr] += xferthroughput
	thr[totalstr] += ishit
	thb[totalstr] += hitbytes

	wtr[week] += 1
	wxr[week] += isxfer
	wxb[week] += xferbytes
	wxt[week] += xferthroughput
	whr[week] += ishit
	whb[week] += hitbytes

	mtr[method] += 1
	mxr[method] += isxfer
	mxb[method] += xferbytes
	mxt[method] += xferthroughput
	mhr[method] += ishit
	mhb[method] += hitbytes

	if (neighbor != "-") {
		ntr[neighbor] += 1
		nxr[neighbor] += isxfer
		nxb[neighbor] += xferbytes
		nxt[neighbor] += xferthroughput
		nhr[neighbor] += ishit
		nhb[neighbor] += hitbytes
	}

	if (isdeny) {
		denied[client]++
		numdenies++
	}

	if (match(url, /:\/\/[^:\/]+/)) {
		hostname = substr(url, RSTART + 3, RLENGTH - 3)
		dtr[hostname] += 1
		dxr[hostname] += isxfer
		dxb[hostname] += xferbytes
		dxt[hostname] += xferthroughput
		dhr[hostname] += ishit
		dhb[hostname] += hitbytes
	}

	if (length(objtype) <= 1) {
		IGNORECASE = 1
		if (match(url, /\.gif$/) != 0) objtype = "Graphics"
		else if (match(url, /\.jpe?g$/) != 0) objtype = "Graphics"
		else if (match(url, /\.xbm$/) != 0) objtype = "Graphics"
		else if (match(url, /\.s?html?$/) != 0) objtype = "HTML"
		else if (match(url, /^http.+\/$/) != 0) objtype = "HTML"
		else if (match(url, /\.doc$/) != 0) objtype = "ASCII"
		else if (match(url, /\.txt$/) != 0) objtype = "ASCII"
		else if (match(url, /\.wav$/) != 0) objtype = "Sound"
		else if (match(url, /\.snd$/) != 0) objtype = "Sound"
		else if (match(url, /\.au$/) != 0) objtype = "Sound"
		else if (match(url, /\.exe$/) != 0) objtype = "Binary"
		else if (match(url, /\.zip$/) != 0) objtype = "Archive"
		else if (match(url, /\.arj$/) != 0) objtype = "Archive"
		else if (match(url, /\.tar$/) != 0) objtype = "Archive"
		else if (match(url, /\.tar\.g?z$/) != 0) objtype = "Archive"
		else if (match(url, /\.hqx$/) != 0) objtype = "Archive"
		else if (match(url, /\.mov$/) != 0) objtype = "Movie"
		else if (match(url, /\.mpe?g$/) != 0) objtype = "Movie"
		else objtype = "unknown/unknown"
		IGNORECASE = 0
	}

	otr[objtype] += 1
	oxr[objtype] += isxfer
	oxb[objtype] += xferbytes
	oxt[objtype] += xferthroughput
	ohr[objtype] += ishit
	ohb[objtype] += hitbytes
}
END {
	print "Parsed lines  : " ttr[totalstr]
	print "Bad lines     : " badlines
	print ""
	print "First request : " strftime("%c", firstreq)
	print "Last request  : " strftime("%c", lastreq)
	printf "Number of days: %.1f\n", (lastreq - firstreq) / 86400

	if (numdenies != 0) {
		print ""
		print "Denied clients                  reqs"
		print "------------------------- ----------"
		for (ipnr in denied) printf "%-25s %10d\n", ipnr, denied[ipnr] | "sort"
		close("sort")
	}

	print_table("Top 10 sites by xfers", "sort -r -n -k 1 2>/dev/null | head -10", dtr, dxr, dxb, dxt, dhr, dhb)
	print_table("Top 10 sites by MB", "sort -r -n -k 6 2>/dev/null | head -10", dtr, dxr, dxb, dxt, dhr, dhb)
	print_table("Top 10 neighbor report", "sort -r -n -k 6 2>/dev/null | head -10", ntr, nxr, nxb, nxt, nhr, nhb)
	print_table("Local code", "sort", ltr, lxr, lxb, lxt, lhr, lhb)
	print_table("Status code", "sort", str, sxr, sxb, sxt, shr, shb)
	print_table("Hierarchie code", "sort", htr, hxr, hxb, hxt, hhr, hhb)
	print_table("Method report", "sort", mtr, mxr, mxb, mxt, mhr, mhb)
	print_table("Object type report", "sort -r -n -k 6", otr, oxr, oxb, oxt, ohr, ohb)
	print_table("Ident (User) Report", "sort -r -n -k 6", utr, uxr, uxb, uxt, uhr, uhb)
	print_table("Weekly report", "sort", wtr, wxr, wxb, wxt, whr, whb)
	print_table("Total report", "cat", ttr, txr, txb, txt, thr, thb)

	print ""
	print "Produced by : Mollie's hacked access-flow 0.5"
	print "Running time: " (systime() - analysis_start) " seconds"
}

function print_table(title, filter, tr, xr, xb, xt, hr, hb) {

	print ""
	printf "%-25.25s ", title
	print "      reqs   %all %xfers   %hit         MB   %all   %hit     kB/xf      kB/s"
	print "------------------------- ------------------------------- ------------------------ -------------------"

	for (c in tr) {
		printf "%-25.25s ", c | filter
		printf "%10d %5.1f%% ", tr[c], tr[c]/ttr[totalstr]*100 | filter
		printf "%5.1f%% ", xr[c]/tr[c]*100 | filter
		if (xr[c] == 0) printf "     - " | filter
			else printf "%5.1f%% ", hr[c]/xr[c]*100 | filter
		#printf "%7.1f %5.1f%% ", xb[c]/1048576, xb[c]/txb[totalstr]*100 | filter
		printf "%10.1f %5.1f%% ", xb[c]/1048576, xb[c]/txb[totalstr]*100 | filter
		if (xb[c] == 0) printf "     - " | filter
			else printf "%5.1f%% ", hb[c]/xb[c]*100 | filter
		if (xr[c] == 0) printf "        -         -\n" | filter
			else printf "%9.1f %9.1f\n", xb[c]/1024/xr[c], xt[c]/1.024/xr[c] | filter
			#else printf "%6.1f %6.1f\n", xb[c]/1024/xr[c], xt[c]/1.024/xr[c] | filter
	}

	close(filter)
}

