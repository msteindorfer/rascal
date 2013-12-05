package org.eclipse.imp.pdb.facts.tracking;

public class Node {

	private final static String PREFIX = "value";
	private final static int LABEL_TRASHHOLD = 20;
	
	private final String representation;
	
	Node(Object object, String digest) {
		final String value = object.toString();
		final StringBuilder result = new StringBuilder();
		
		result.append(PREFIX);
		result.append(digest);
		if (value.length() > LABEL_TRASHHOLD) {
			result.append(String.format(" [label=\"%s...\"]", value.substring(0, LABEL_TRASHHOLD).replace("\"", "'")));
		} else {
			result.append(String.format(" [label=\"%s\"]", value));
		}
		this.representation = result.toString();
	}
	
	public String getId() {
		return representation.split(" ")[0];
	}

	public String getDigest() {
		return representation.split(" ")[0].substring(PREFIX.length());
	}
	
	public String getMetadata() {
		return representation.split(" ")[1];
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
	
}
