var lambda_base = "http://localhost:4567"
var iterativeParams = [];
var urlbase = "";
var pageparams = {};

$(document).ready(function(){
  $("#exportTable").on('click', function(){
    exportTable($('table tbody tr:visible'));
  });
  pageparams = getParams();
  var path = ('path' in pageparams) ? pageparams['path'] : '';
  urlbase = path == '' ? '' : lambda_base + "/" + path;
  var url = path == '' ? '' : urlbase; // + document.location.search;

  if (url != '') {
    showUrl(url);
    $("#menu").hide();
  } else {
    $("#menu").show();
  }
});

function iterateParams(parr) {
  params = pageparams;
  delete params['iterate'];
  params['itparam1'] = parr.length > 0 ? parr[0] : '';
  params['itparam2'] = parr.length > 1 ? parr[1] : '';
  params['itparam3'] = parr.length > 2 ? parr[2] : '';
  return params;
}

function getParams(){
  var queries = {};
  if (document.location.search == "") {
    return queries;
  }
  $.each(document.location.search.substr(1).split('&'),function(c,q){
    var i = q.split('=');
    queries[i[0].toString()] = i[1].toString();
  });
  return queries;
}

function showData(file) {
  var url = "data/" + file + ".json";
  showUrl(url);
}

function showUrl(url) {
  $("#in-progress").dialog({
    title: "Please wait",
    modal: true,
    width: 350,
    position: {
      my: "center",
      at: "center",
      of: window,
      collision: "none"
    }
  });
  $.ajax({
    dataType: "json",
    url: url,
    data: pageparams,
    success: function(data) {
      $("h1").text(data.title);
      createTable(
        data.headers,
        data.types,
        data.data,
        data.filter_col,
        data.merritt_path,
        data.iterate
      )
    },
    error: function( xhr, status ) {
      alert("An error has occurred.  Possibly a timeout.\n"+xhr.responseText)
      $("#in-progress").dialog("close");
    }
  });
}

function query_iterate(){
  if (iterativeParams.length == 0) {
    sorttable.makeSortable($("#data-table")[0]);
    $("#in-progress").dialog("close");
    $("#iprogress").text("");
  } else {
    var itparam = iterativeParams.shift();
    $("#iprogress").text("Queries Remaining: "+iterativeParams.length);
    $.ajax({
      dataType: "json",
      url: urlbase,
      data: iterateParams(itparam),
      success: function(data) {
        appendTable(
          data.headers,
          data.types,
          data.data,
          data.filter_col,
          data.merritt_path
        )
      },
      error: function( xhr, status ) {
        alert("An error has occurred.  Possibly a timeout.\n"+xhr.responseText)
        $("#in-progress").dialog("close");
      }
    });
  }
}

function createTable(headers, types, data, filter_col, merritt_path, iterate) {
  $("#data-table")
    .empty()
    .append($("<thead/>"))
    .append($("<tbody/>"));
  if (iterate) {
    iterativeParams = data;
    query_iterate();
  } else {
    appendTable(headers, types, data, filter_col, merritt_path);
  }
}

function appendTable(headers, types, data, filter_col, merritt_path) {
  if ($("#data-table tr.header").length == 0) {
    var tr = $("<tr/>").appendTo("#data-table thead");
    tr.addClass("header");
    for(var c=0; c<headers.length; c++) {
      if (types[c] != 'na') {
        tr.append(createCell(headers[c], types[c], true, merritt_path));
      }
    }
  }

  for(var r=0; r<data.length; r++) {
    tr = $("<tr/>").appendTo("#data-table tbody")

    rclass = "row";
    if (filter_col) {
      if (data[r][filter_col] == '-- Total --') {
        rclass = "total"
      } else if (data[r][filter_col] == '-- Grand Total --') {
        rclass = "grandtotal"
      } else if (data[r][filter_col] == '-- Special Total --') {
        rclass = "specialtotal"
      }
    }
    tr.addClass(rclass);

    for(var c=0; c<data[r].length; c++) {
      if (types[c] != 'na') {
        tr.append(createCell(data[r][c], types[c], false, merritt_path));
      }
    }
    if (tr.find("td.hasdata,th.hasdata").length == 0) {
      tr.addClass("nodata");
    }
  }
  $("#in-progress").dialog({
    position: {
      my: "center",
      at: "center",
      of: window,
      collision: "none"
    }
  });
  query_iterate();
}

function createCell(v, type, isHeader, merritt_path) {
  var cell = isHeader ? $("<th/>") : $("<td/>");
  cell.addClass("cell").addClass(type);
  format(cell, v, isHeader ? '' : type, merritt_path);
  return cell;
}

function format(cell, v, type, merritt_path) {
  if (v == null) {
  } else if (type == 'foo') {
    $("<a href='?json=foo'/>").text(v).appendTo(cell);
  } else if (type == 'money'){
    cell.text(Number(v).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits:2}));
    cell.addClass("hasdata");
  } else if (type == 'dataint'){
    cell.text(Number(v).toLocaleString());
    cell.addClass("hasdata");
  } else if (type == 'data'){
    cell.text(Number(v).toLocaleString());
    cell.addClass("hasdata");
  } else if (type == 'node' && Number(v) > 0){
    link = $("<a/>")
      .text(v)
      .attr("href", "index.html?path=collections_by_node&node="+v)
      .appendTo(cell);
  } else if (type == 'own' && Number(v) > 0){
    link = $("<a/>")
      .text(v)
      .attr("href", "index.html?path=collections_by_owner&own="+v)
      .appendTo(cell);
  } else if (type == 'mime' && !v.startsWith('--')){
    link = $("<a/>")
      .text(v)
      .attr("href", "index.html?path=collections_by_mime_type&mime="+v)
      .appendTo(cell);
  } else if (type == 'gmime' && v != '' && !v.startsWith('ZZ')){
    link = $("<a/>")
      .text(v)
      .attr("href", "index.html?path=collections_by_mime_group&mime="+v)
      .appendTo(cell);
  } else if (type == 'coll' && Number(v) > 0){
    link = $("<a/>")
      .text(v)
      .attr("href", "index.html?path=collection_details&coll="+v)
      .appendTo(cell);
  } else if (type == 'ogroup' && !v.startsWith('ZZ')){
    link = $("<a/>")
      .text(v)
      .attr("href", "index.html?path=collection_group_details&coll="+v)
      .appendTo(cell);
  } else if (type == 'mnemonic'){
    link = $("<a/>")
      .text(v)
      .attr("href", merritt_path + "/m/" + v)
      .appendTo(cell);
  } else if (type == 'ark'){
    link = $("<a/>")
      .text(v)
      .attr("href", merritt_path + "/m/" + encodeURIComponent(v))
      .appendTo(cell);
    cell.addClass("hasdata");
  } else {
    cell.text(v);
  }
}


var Report = function() {
    var self = this;
    this.makeCsv = function(rows) {
        var itemdata = "";
        rows.each(function(rownum, row){
            itemdata += (rownum == 0) ? "" : "\r\n";
            $(row).find("td,th").each(function(colnum, col){
                itemdata += self.exportCol(colnum, col);
            });
        });
        return itemdata;
    }

    this.export = function(rows) {
    var itemdata = "data:text/csv;charset=utf-8," + this.makeCsv(rows);
        var encodedUri = encodeURI(itemdata);
        window.open(encodedUri);
    }

    //this is meant to be overridden for each report
    this.exportCol = function(colnum, col) {
        var data = "";
        data += (colnum == 0) ? "" : ",";
        data += self.exportCell(col);
        return data;
    }

    this.exportCell = function(col) {
        data = "\"";
        $(col).contents().each(function(i, node){
            if ($(node).is("hr")) {
                data += "||";
            } else {
                data += $(node).text().replace(/\n/g," ").replace(/"/g,"\"\"").replace(/\s/g," ");
                if ($(node).is("div:not(:last-child)")) {
                    data += "||";
                }
            }
        });
        data += "\"";
        return data;
    }
}

function exportTable(rows) {
  var ReportObj = new Report();
  ReportObj.export(rows);
}
