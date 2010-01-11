#!/usr/bin/env ruby

macro :note do |params|
	%{
		<div class="note">
			<span class="note-title">Note</span>
			<span class="note-body">#{params[0]}</span>
		</div>
	}
end
