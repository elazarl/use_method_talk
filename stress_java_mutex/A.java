class A {
	public static void sleep(int sec) {
		try {
			Thread.sleep(sec*1000);
		} catch (InterruptedException ignored) {
		}
	}
	synchronized private static void f() {
		System.out.println("f called "+Thread.currentThread().getId());
		for (int i=0; i<10; i++) {
			System.out.println("wait "+i);
			sleep(24);
		}
	}
	public static void main(String[] args) {
		System.out.println("howdy");
		for (int i=0;i<100;i++) {
			new Thread(() -> {  f(); }, "waiter_"+i).start();
		}
		f();
		System.out.println("bye");
	}
}
