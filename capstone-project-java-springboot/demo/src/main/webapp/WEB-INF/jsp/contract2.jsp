<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <title>OurApp</title>
    <link href="https://fonts.googleapis.com/css?family=Public+Sans:300,400,400i,700,700i&display=swap"
        rel="stylesheet" />
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css"
        crossorigin="anonymous" />
    <script defer src="https://use.fontawesome.com/releases/v5.5.0/js/all.js" crossorigin="anonymous"></script>
    <link rel="stylesheet" href="/css/main.css" />

    <style>
        td.header-row {
            background-color: gold;
            font-weight: 700;
        }

        app th,
        td,
        p,
        input {
            font: 14px Verdana;
        }

        app table,
        th,
        td {
            border: solid 1px #DDD;
            border-collapse: collapse;
            padding: 2px 3px;
            text-align: center;
        }

        app th {
            font-weight: bold;
        }
    </style>
    <script async>

        async function getcontracts() {
            document.getElementById('status').innerText = 'fetching data';

            let response = await fetch("http://localhost:8085/contracts2");

            if (response.ok) { // if HTTP-status is 200-299
                // get the response body (the method explained below)
                let json = await response.json();
                console.log(json);

                var col = [];
                for (var i = 0; i < json.length; i++) {
                    for (var key in json[i]) {
                        if (col.indexOf(key) === -1) {
                            col.push(key);
                        }
                    }
                }

                // CREATE DYNAMIC TABLE.
                var table = document.createElement("table");
                table.className = "table";

                // ADD JSON DATA TO THE TABLE AS ROWS.
                for (var i = 0; i < json.length; i++) {

                    tr = table.insertRow(-1);
                    let obj = json[i];
                    var tabCell = tr.insertCell(-1);
                    tabCell.innerHTML = obj["Key"];
                    let record = obj["Record"];
                    tabCell = tr.insertCell(-1);
                    tabCell.innerHTML = record["contractfor"];

                    tabCell = tr.insertCell(-1);
                    tabCell.innerHTML = record["status"];
                    tabCell = tr.insertCell(-1);
                    tabCell.innerHTML = record["ContractValue"];
                }

                tr = table.insertRow(0);
                tabCell = tr.insertCell(-1);
                tabCell.className = 'header-row';
                tabCell.innerHTML = "Contract ID";
                tabCell = tr.insertCell(-1); tabCell.className = 'header-row'; tabCell.innerHTML = "Contract Name";
                tabCell = tr.insertCell(-1); tabCell.className = 'header-row'; tabCell.innerHTML = "Contract Status";
                tabCell = tr.insertCell(-1); tabCell.className = 'header-row'; tabCell.innerHTML = "Contract Value";

                // FINALLY ADD THE NEWLY CREATED TABLE WITH JSON DATA TO A CONTAINER.
                var divContainer = document.getElementById("divContainer");
                divContainer.innerHTML = "";
                divContainer.appendChild(table);
            } else {
                alert("HTTP-Error: " + response.status);
            }
            document.getElementById('status').innerText = ''
        }

        async function createAlbum(eve) {
            document.getElementById('status').innerText = 'Posting data';
            eve.preventDefault();
            const url = 'http://localhost:8085/albums/create2?contractfor=' + document.getElementById('album-name').value;
            // post body data
            const mediaContract = {
                contractFor: 'from the app'
            };
            // create request object
            const request = new Request(url, {
                method: 'POST',
                body: JSON.stringify("'contractfor': 'from the app'"),
                headers: new Headers({
                    'Content-Type': 'application/json'
                })
            });

            // pass request object to `fetch()`
            fetch(request)
                //  .then(res => res.json())
                .then(res => document.getElementById('status').innerText = 'fetching data')
                .then(res => {
                    getcontracts();
                    document.getElementById('status').innerText = '';
                });

        }
    </script>
</head>

<body>
    <header class="header-bar bg-primary mb-3">
        <div class="container d-flex flex-column flex-md-row align-items-center p-3">
            <h4 class="my-0 mr-md-auto font-weight-normal">
                <a href="/" class="text-white">
                    Music Sells on the 2nd Channel
                </a>
            </h4>
            <form class="mb-0 pt-2 pt-md-0">
                <div class="row align-items-center">
                    <div class="col-md mr-0 pr-md-0 mb-3 mb-md-0">
                        <input name="username" class="form-control form-control-sm input-dark" type="text"
                            placeholder="Username" autocomplete="off" />
                    </div>
                    <div class="col-md mr-0 pr-md-0 mb-3 mb-md-0">
                        <input name="password" class="form-control form-control-sm input-dark" type="password"
                            placeholder="Password" />
                    </div>
                    <div class="col-md-auto">
                        <button class="btn btn-success btn-sm">Sign In</button>
                    </div>
                </div>
            </form>
        </div>
    </header>

    <div class="container py-md-5">
        <div class="row align-items-center">

            <div class="col-lg-5 pl-lg-5 pb-3 py-lg-5">
                <form>
                    <div class="form-group">
                        <label for="album-name" class="text-muted mb-1">
                            <small>Album Name</small>
                        </label>
                        <input id="album-name" name="username" class="form-control" type="text"
                            placeholder="In God We Trust" autocomplete="off" />
                    </div>
                    <div class="form-group">
                        <label for="email-register" class="text-muted mb-1">
                            <small>Album Author</small>
                        </label>
                        <input id="email-register" name="email" class="form-control" type="text"
                            placeholder="Michael Jackson" autocomplete="off" />
                    </div>
                    <div class="form-group">
                        <label for="password-register" class="text-muted mb-1">
                            <small>Album Type</small>
                        </label>
                        <input id="password-register" name="password" class="form-control" type="text"
                            placeholder="Rap, Classical, Pop" />
                    </div>
                    <button class="py-3 mt-4 btn btn-lg btn-success btn-block" onclick="return createAlbum(event)">
                        Create Album
                    </button>
                </form>
            </div>
            <div class="col-lg-7 py-3 py-md-5">
                <h1 class="display-3">Album List</h1>
                <h2 id="status">test</h2>
                <p class="lead text-muted">
                <div id="divContainer">
                    </p>
                </div>
            </div>
        </div>

        <footer class="border-top text-center small text-muted py-3">
            <p><a href="/" class="mx-1">Home</a> | <a class="mx-1" href="/about-us">About Us</a> | <a class="mx-1"
                    href="/terms">Terms</a>
            </p>
            <p class="m-0">Copyright &copy; 2020 <a href="/" class="text-muted">Music Sells!</a>. All rights reserved.
            </p>
        </footer>
        <script async> getcontracts();</script>
</body>

</html>