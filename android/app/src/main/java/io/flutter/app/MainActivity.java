package io.flutter.app;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.content.Intent;
import android.net.Uri;
import androidx.core.content.FileProvider;
import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "app.tracer/share";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "shareFiles":
                            List<String> filePaths = call.argument("filePaths");
                            String text = call.argument("text");
                            String subject = call.argument("subject");
                            
                            shareFiles(filePaths, text, subject);
                            result.success(null);
                            break;
                        case "shareText":
                            String shareText = call.argument("text");
                            String shareSubject = call.argument("subject");
                            
                            shareText(shareText, shareSubject);
                            result.success(null);
                            break;
                        default:
                            result.notImplemented();
                    }
                });
    }

    private void shareFiles(List<String> filePaths, String text, String subject) {
        Intent intent = new Intent();
        
        if (filePaths.size() == 1) {
            // Share a single file
            intent.setAction(Intent.ACTION_SEND);
            File file = new File(filePaths.get(0));
            Uri contentUri = FileProvider.getUriForFile(this, getPackageName() + ".fileprovider", file);
            intent.putExtra(Intent.EXTRA_STREAM, contentUri);
        } else {
            // Share multiple files
            intent.setAction(Intent.ACTION_SEND_MULTIPLE);
            ArrayList<Uri> contentUris = new ArrayList<>();
            
            for (String path : filePaths) {
                File file = new File(path);
                Uri contentUri = FileProvider.getUriForFile(this, getPackageName() + ".fileprovider", file);
                contentUris.add(contentUri);
            }
            
            intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, contentUris);
        }
        
        // Set other intent properties
        intent.setType("*/*");
        
        if (subject != null && !subject.isEmpty()) {
            intent.putExtra(Intent.EXTRA_SUBJECT, subject);
        }
        
        if (text != null && !text.isEmpty()) {
            intent.putExtra(Intent.EXTRA_TEXT, text);
        }
        
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        startActivity(Intent.createChooser(intent, "Share via"));
    }

    private void shareText(String text, String subject) {
        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.setType("text/plain");
        intent.putExtra(Intent.EXTRA_TEXT, text);
        
        if (subject != null && !subject.isEmpty()) {
            intent.putExtra(Intent.EXTRA_SUBJECT, subject);
        }
        
        startActivity(Intent.createChooser(intent, "Share via"));
    }
}
