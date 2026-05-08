import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _appVersion = 'v1.0.0+1';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'সাহায্য',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎯 ইসলামিক কুইজ কিভাবে খেলবেন?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'আপনার ইসলামিক জ্ঞান পরীক্ষা করুন এবং উন্নত করুন',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Step 1
          _buildHelpSection(
            title: '১. কুইজ শুরু করুন',
            content:
                'হোম স্ক্রিন থেকে যেকোনো ক্যাটাগরি নির্বাচন করুন। উপলব্ধ বিভিন্ন ইসলামিক বিষয়ের কুইজ খেলুন।',
            icon: '📚',
          ),

          // Step 2
          _buildHelpSection(
            title: '২. প্রশ্নের উত্তর দিন',
            content:
                'প্রতিটি প্রশ্নে মনোযোগ সহকারে পড়ুন এবং সঠিক উত্তর বেছে নিন। আপনার সময় সীমিত, তাই তাড়াতাড়ি সিদ্ধান্ত নিন।',
            icon: '✍️',
          ),

          // Step 3
          _buildHelpSection(
            title: '৩. ফলাফল দেখুন',
            content:
                'কুইজ শেষ করার পরে আপনার স্কোর এবং নির্ভুলতা দেখুন। প্রতিটি প্রশ্নের সঠিক উত্তর জানতে পারবেন।',
            icon: '📊',
          ),

          // Step 4
          _buildHelpSection(
            title: '৪. আপনার অগ্রগতি ট্র্যাক করুন',
            content:
                'প্রোফাইল সেকশনে গিয়ে আপনার মোট কুইজ সংখ্যা, জয়ের হার এবং নির্ভুলতা দেখুন। লিডারবোর্ডে আপনার র‍্যাঙ্ক চেক করুন।',
            icon: '🏆',
          ),

          // Step 5
          _buildHelpSection(
            title: '৫. ব্যাজ এবং অর্জন পান',
            content:
                'আরও বেশি কুইজ খেলুন এবং আপনার স্তর বৃদ্ধি করুন। বিভিন্ন অর্জন আনলক করুন এবং আপনার দক্ষতা প্রদর্শন করুন।',
            icon: '⭐',
          ),

          // Tips Section
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 দরকারি টিপস',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  '✓ প্রতিদিন কমপক্ষে একটি কুইজ খেলুন নিয়মিত জ্ঞান বৃদ্ধির জন্য।',
                ),
                _buildTipItem(
                  '✓ আপনার ত্রুটিগুলি থেকে শিখুন এবং পরে সেই বিষয়ে আরও মনোযোগ দিন।',
                ),
                _buildTipItem(
                  '✓ লিডারবোর্ডে বন্ধুদের সাথে প্রতিযোগিতা করুন এবং অনুপ্রাণিত থাকুন।',
                ),
                _buildTipItem(
                  '✓ আপনার প্রোফাইল সম্পন্ন করুন যাতে আপনার অগ্রগতি সঠিকভাবে সংরক্ষিত থাকে।',
                ),
              ],
            ),
          ),

          // FAQ Section
          const SizedBox(height: 20),
          Text(
            'সাধারণ প্রশ্ন ও উত্তর',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            'আমি একই কুইজ আবার খেলতে পারি?',
            'হ্যাঁ, আপনি যেকোনো কুইজ যতবার খুশি খেলতে পারেন। প্রতিটি খেলা আপনার স্কোরে যোগ হবে।',
          ),
          _buildFaqItem(
            'মেরা স্কোর অন্যদের সাথে শেয়ার করা যায়?',
            'হ্যাঁ, ফলাফল স্ক্রিনে শেয়ার বাটন দিয়ে আপনার স্কোর বন্ধুদের কাছে পাঠাতে পারেন।',
          ),
          _buildFaqItem(
            'জয়ের হার কীভাবে হিসাব করা হয়?',
            'যে কুইজগুলিতে আপনি ৭০% বা তার বেশি স্কোর করেছেন সেগুলি জয় হিসাবে গণনা করা হয়।',
          ),
          _buildFaqItem(
            'আমি অফলাইনে কুইজ খেলতে পারি?',
            'কুইজ খেলার জন্য ইন্টারনেট সংযোগ প্রয়োজন। তবে আপনার রেজাল্ট অটোমেটিকালি সংরক্ষিত হয়।',
          ),

          // Version Info
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Text(
                  'Islamic Quiz',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _appVersion,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'May Allah accept our efforts',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHelpSection({
    required String title,
    required String content,
    required String icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        tip,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade700,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
