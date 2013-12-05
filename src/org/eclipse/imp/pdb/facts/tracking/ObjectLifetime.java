package org.eclipse.imp.pdb.facts.tracking;


public class ObjectLifetime implements Comparable<ObjectLifetime> {

	long tag;
	byte[] digest;
	long ctorTime = -1;
	long dtorTime = -1;
	long measuredSizeInBytes = -1;
	
	public ObjectLifetime(long tag, long ctorTime) {
		this.tag = tag;
		this.ctorTime = ctorTime;
	}

	public void setDigest(byte[] digest) {
		this.digest = digest;
	}

	public byte[] getDigest() {
		return digest;
	}
	
	public void setCtorTime(long ctorTime) {
		this.ctorTime = ctorTime;
	}
	
	long getCtorTime() {
		return ctorTime;
	}

	public void setDtorTime(long dtorTime) {
		this.dtorTime = dtorTime;
	}
	
	long getDtorTime() {
		return dtorTime;
	}

	@Override
	public String toString() {
		String result = String.format("<\"%s\",%d,%d,%d>",
				digest,
				ctorTime, dtorTime, measuredSizeInBytes);
		return result;
	}


	@Override
	public int compareTo(ObjectLifetime that) {
		return (int) (this.ctorTime - that.ctorTime);
	}
	
	public TrackingProtocolBuffers.ObjectLifetime toProtoBuf() {
		TrackingProtocolBuffers.ObjectLifetime.Builder bldr = TrackingProtocolBuffers.ObjectLifetime.newBuilder()
				.setTag(tag)
				.setDigest(toHexString(digest))
				.setCtorTime(ctorTime);
		
		if (dtorTime != -1) {
			bldr.setDtorTime(dtorTime);
		}
		
		if (measuredSizeInBytes != -1) {
			bldr.setMeasuredSizeInBytes(measuredSizeInBytes);
		}
		
		return bldr.build();
				
	}
	
	protected static String toHexString(byte[] bytes) {
		char[] hexChars = toHexCharArray(bytes);
		return new String(hexChars);
	}	
	
	/**
	 * Converts a byte array into a hex string with leading zeros.
	 * 
	 * For a discussion about the implementation see: 
	 * http://stackoverflow.com/questions/332079/in-java-how-do-i-convert-a-byte-array-to-a-string-of-hex-digits-while-keeping-l
	 * 
	 * @param bytes an input byte array
	 * @return hex string with capital letters
	 */
	protected static char[] toHexCharArray(byte[] bytes) {
		char[] hexArray = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
				'A', 'B', 'C', 'D', 'E', 'F' };
		char[] hexChars = new char[bytes.length * 2];
		
		int charPairAsInt;
		for (int i = 0; i < bytes.length; i++) {
			charPairAsInt = bytes[i] & 0xFF;
			hexChars[i * 2]     = hexArray[charPairAsInt / 16]; // first  character
			hexChars[i * 2 + 1] = hexArray[charPairAsInt % 16]; // second character
		}
		return hexChars;
	}
	
}
