
macro :error_table do
	%{
		<table>
			<tr>
				<th>Error</th>
				<th>Description</th>
			</tr>
			#{@value}
		</table>
	}
end

macro :ref_error do
	error, description = @params
	%{
		<tr>
			<td>#{error}</td>
			<td>#{description}</td>
		</tr>
	}
end
