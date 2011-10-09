component output="false" {

	public GitHubJSONParser function init( required string jsonURL ) {
		variables.jsonURL = arguments.jsonURL;
		variables.targetType = '';
		variables.itemLimit = 3;
		variables.theJSON = '';
	
		return this;
	}
	
	public GitHubJSONParser function setTargetType( required string type ) {
		variables.targetType = arguments.type;
		//Returning the object so that I can chain methods
		return this;
	}
	
	public GitHubJSONParser function setItemLimit( required numeric limit ) {
		variables.itemLimit = arguments.limit;
		return this;
	}
	
	public array function getCleanJSON() {
		setDirtyJSON( makeHttpRequestAndReturnJSON() );
		return makeCleanJSON();
	}
	
	private array function makeHttpRequestAndReturnJSON() {
		var httpSvc = new http();
		var json = '';
		
		httpSvc.setUrl( variables.jsonURL );
		httpSvc.addParam( type='CGI', name='accept', value='text/json', encoded='no' );
	
		json = httpSvc.send().getPrefix().filecontent;
		json = deSerializeJSON( json );
	
		return json;
	}
	
	private array function makeCleanJSON() {
		var rArray = arrayNew( 1 );
		//Don't worry about this, I just went overboard with getters and setters
		var json = getDirtyJSON();
		var i = 1;
		
		//Because of potential missing events, I have to keep an "actual count" of
		//items inserted into the struct so that my feed isn't shorter than I want
		//it to be.
		var actualCount = 1;
		
		for(i = 1; actualCount <= variables.itemLimit; i++) {
			//json[i].type contains the type of event for each item
			switch(json[i].type) {
				//Depending on the event, we'll call the correct method and pass it the item in question
				case "PushEvent":
					rArray[ actualCount ] = handlePushEvent( json[i] );
					actualCount++;
					break;
				case "WatchEvent":
					rArray[ actualCount ] = handleWatchEvent( json[i] );
					actualCount++;
					break;
				case "CreateEvent":
					rArray[ actualCount ] = handleCreateEvent( json[i] );
					actualCount++;
					break;
				case "ForkEvent":
					rArray[ actualCount ] = handleForkEvent( json[i] );
					actualCount++;
					break;
				case "FollowEvent":
					rArray[ actualCount ] = handleFollowEvent( json[i] );
					actualCount++;
					break;
				default:
					break;
			}
			
		}
	
		return rArray;
	}
	
	private struct function handlePushEvent( required struct event ) {
		//My cleverly named return struct
		var rStruct = structNew();
		//We'll need the branch and the repository to build the target string
		var branch = listGetAt( arguments.event.payload.ref, 3, "/" );
		var repository = event.repository.owner & "/" & event.repository.name;
		var target = '';
		
		//For my site, I didn't want to include the branch in push events because
		//the string was too long, so I wrote in a little option that can be set
		//to keep it short
		if(variables.targetType EQ "short") {
			target = repository;
		} else {
			target = branch & " at " & repository;
		}
		
		//I use the event field to style the li in the view
		structInsert( rStruct, "event", "push" );
		structInsert( rStruct, "url", arguments.event.url );
		//GitHub's date format is 2011/09/01 19:38:47 -0700, which CF didn't want to work with,
		//so I'm going to pass it on to another method to format it.
		structInsert( rStruct, "date", formatGitHubDateString( arguments.event.created_at ) );
		structInsert( rStruct, "actor", arguments.event.actor );
		structInsert( rStruct, "action", "pushed to" );
		structInsert( rStruct, "target", target );
		
		if(arraylen( arguments.event.payload.shas ) GT 1) {
			structInsert( rStruct, "description", 
		               buildArrayForMultipleCommits( arguments.event.payload.shas ) );
		} else {
			structInsert( rStruct, "description", arguments.event.payload.shas[1][3] );
		}
	
		return rStruct;
	}
	
	private struct function handleWatchEvent( required struct event ) {
		var rStruct = structNew();
		var target = arguments.event.repository.owner & "/" & arguments.event.repository.name;
		
		structInsert( rStruct, "event", "watch" );
		structInsert( rStruct, "url", arguments.event.url );
		structInsert( rStruct, "date", formatGitHubDateString( arguments.event.created_at ) );
		structInsert( rStruct, "actor", arguments.event.actor );
		structInsert( rStruct, "action", arguments.event.payload.action & " watching" );
		structInsert( rStruct, "target", target );
		structInsert( rStruct, "description", arguments.event.repository.description );
	
		return rStruct;
	}
	
	private struct function handleCreateEvent( required struct event ) {
		var rStruct = structNew();
		var type = arguments.event.payload.ref_type;
		var branch = '';
		var repository = arguments.event.repository.owner & "/" & arguments.event.repository.name;
		var target = '';
		
		//For some reason, CF9 will give me a null value for event.payload.ref, but Railo treats it
		//as if it doesn't exist...hence this code
		if(type EQ 'branch') {
			branch = arguments.event.payload.ref;
			target = type & " " & branch & " at " & repository;
		} else {
			target = repository;
		}
	
		structInsert( rStruct, "event", "create" );
		structInsert( rStruct, "url", arguments.event.url );
		structInsert( rStruct, "date", formatGitHubDateString( arguments.event.created_at ) );
		structInsert( rStruct, "actor", arguments.event.actor );
		structInsert( rStruct, "action", "created" );
		structInsert( rStruct, "target", target );
		structInsert( rStruct, "description", arguments.event.repository.description );
	
		return rStruct;
	}
	
	private struct function handleForkEvent( required struct event ) {
		var rStruct = structNew();
		var target = event.repository.owner & "/" & event.repository.name;
		
		structInsert( rStruct, "event", "fork" );
		structInsert( rStruct, "url", arguments.event.url );
		structInsert( rStruct, "date", formatGitHubDateString( arguments.event.created_at ) );
		structInsert( rStruct, "actor", arguments.event.actor );
		structInsert( rStruct, "action", "forked" );
		structInsert( rStruct, "target", target );
		structInsert( rStruct, "description", arguments.event.repository.description );
	
		return rStruct;
	}
	
	private struct function handleFollowEvent( required struct event ) {
		var rStruct = structNew();
		
		structInsert( rStruct, "event", "follow" );
		structInsert( rStruct, "url", arguments.event.url );
		structInsert( rStruct, "date", formatGitHubDateString( arguments.event.created_at ) );
		structInsert( rStruct, "actor", arguments.event.actor );
		structInsert( rStruct, "action", "started following" );
		structInsert( rStruct, "target", arguments.event.payload.target.login );
		structInsert( rStruct, "description", "" );
		
		return rStruct;
	}
	
	private string function formatGitHubDateString( required string ghDate ) {
		var date = dateFormat( listGetAt( arguments.ghDate, 1, " " ), 'dddd, mmmm dd yyyy' );
		var time = timeFormat( listGetAt( arguments.ghDate, 2, " " ), 'h:mm tt' );
		var dateTime = date & " " & time;
		
		return dateTime;
	}
	
	private array function buildArrayForMultipleCommits( required array commits ) {
		var rArray = arrayNew( 1 );
		var i = 1;
		
		for(i = 1; i <= arraylen( arguments.commits ); i++) {
			rArray[i] = arguments.commits[i][3];
		}
	
		return rArray;
	}
	
	private void function setDirtyJSON( required array json ) {
		variables.dirtyJSON = arguments.json;
	}
	
	private array function getDirtyJSON() {
		return variables.dirtyJSON;
	}
	
}