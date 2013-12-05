package org.eclipse.imp.pdb.facts.tracking;

public class Edge {
	
	private final String representation; 
	
	private final Node fromNode;
	private final Node toNode;
	
	private final ObjectLifetime fromOLT;
	private final ObjectLifetime toOLT;

	Edge(Node from, Node to, String label, long callId) {
		StringBuilder result = new StringBuilder();
		
		result.append(from.getId());
		result.append(" -> ");
		result.append(to.getId());
		result.append(String.format(" [label=\"%s\", callId=%d]", label, callId));

		representation = result.toString();
		
		this.fromNode = from;
		this.toNode = to;
		
		this.fromOLT = null;
		this.toOLT = null;
	}
	
	Edge(Node from, ObjectLifetime fromOLT, Node to, ObjectLifetime toOLT, String label, long callId) {
		StringBuilder result = new StringBuilder();
		
		result.append(from.getId());
		result.append(" -> ");
		result.append(to.getId());
		result.append(String.format(" [label=\"%s\", callId=%d]", label, callId));

		representation = result.toString();
		
		this.fromNode = from;
		this.toNode = to;
		
		this.fromOLT = fromOLT;
		this.toOLT = toOLT;
	}
	
	@Override
	public String toString() {
		return representation;
	}

	@Override
	public int hashCode() {
		return representation.hashCode();
	}

	@Override
	public boolean equals(Object obj) {
		return representation.equals(obj.toString());
	}

	public Node getFrom() {
		return fromNode;
	}

	public Node getTo() {
		return toNode;
	}

	public ObjectLifetime getFromOLT() {
		return fromOLT;
	}

	public ObjectLifetime getToOLT() {
		return toOLT;
	}
	
}
