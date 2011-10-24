<cfoutput>
	<div id="githubfeed" >
		<a href="http://www.github.com/s992" >
			<h3>
				github.com/s992
			</h3>
		</a>
		<ul class="feed" >
			<cfset myJSON = new GitHubJSONParser( 'https://github.com/s992.json' ).getCleanJSON() />
			<cfloop from="1" to="#arrayLen(myJSON)#" index="i">
				<li class="feedItem #myJSON[i].event#" >
					<a href="#myJSON[i].url#" class="updateLink" >
						...
						#myJSON[i].action# 
						#myJSON[i].target#
					</a>
					<p class="updateMessage" >
						<cfif isArray( myJSON[i].description ) >
							<cfset commitCount = arrayLen( myJSON[i].description ) />

							Multiple commits:
							<ul class="commits" >
								<cfloop from="1" to="3" index="j" >
									<li>
										#myJSON[i].description[j]#
									</li>
								</cfloop>
								<cfif commitCount GT 3>
									<li>
										#commitCount - 3# more commits...
									</li>
								</cfif>
							</ul>
						<cfelse>
						#myJSON[i].description#
					</cfif>
				</p>
				<div class="lastUpdated" >
					#myJSON[i].date#
				</div>
			</li>
		</cfloop>
		</ul>
	</div>
</cfoutput>