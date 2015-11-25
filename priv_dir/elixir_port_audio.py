import pyaudio
import sys
import getopt
import time
from io import BytesIO

def main(argv):
	max_chunk_bytes = 8
	bitrate = 32
	channels = 2
	rate = 22050
	pause = b'pause000'

	try:
		opts, args = getopt.getopt(argv, "b:c:r", ["bitrate=", "channels=", "rate="])
	except getopt.GetoptError:
		sys.exit(2)

	for opt, arg in opts:
		if opt in ("-b", "--bitrate"):
			bitrate = arg
		elif opt in ("-c", "--channels"):
			channels = arg
		elif opt in ("-r", "--rate"):
			rate = arg

	bytes = int(bitrate / 8)
	#p = pyaudio.PyAudio()
	buf = BytesIO()

	#def callback(in_data, frame_count, time_info, status):
	#	while buf.getbuffer().nbytes < bytes:
	#		time.sleep(0.1)	# buffer a bit
	#	data = buf.read(bytes)
	#	return (data, pyaudio.paContinue)

	#stream = p.open(format = p.get_format_from_width(bytes),
	#				channels = channels,
	#				rate = rate,
	#				output = True,
	#				stream_callback = callback)

	#stream.start_stream()

	f = open("test.mp4", 'ab')
	while True:
		chunk = sys.stdin.buffer.raw.read(max_chunk_bytes)
		if chunk == pause:
			sys.stdout.buffer.raw.write(b'PAAAAAAAAAAUUUUUUUUUUSE')
			break;
		f.write(chunk)
		buf.write(chunk)
	f.close()

	#while stream.is_active():
	#	timer.sleep(0.1)

	#stream.stop_stream
	#stream.close()
	#p.terminate()

if __name__ == "__main__":
	main(sys.argv[1:])